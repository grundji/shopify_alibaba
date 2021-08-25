# frozen_string_literal: true

require "base64"
require "json"

module Script
  module Layers
    module Infrastructure
      class ScriptService
        include SmartProperties
        property! :ctx, accepts: ShopifyCli::Context

        def push(
          uuid:,
          extension_point_type:,
          script_content:,
          api_key: nil,
          force: false,
          metadata:,
          script_json:
        )
          url = UploadScript.new(ctx).call(api_key, script_content)

          query_name = "app_script_set"
          variables = {
            uuid: uuid,
            extensionPointName: extension_point_type.upcase,
            title: script_json.title,
            description: script_json.description,
            force: force,
            schemaMajorVersion: metadata.schema_major_version.to_s, # API expects string value
            schemaMinorVersion: metadata.schema_minor_version.to_s, # API expects string value
            scriptJsonVersion: script_json.version,
            configurationUi: script_json.configuration_ui,
            configurationDefinition: script_json.configuration&.to_json,
            moduleUploadUrl: url,
          }
          resp_hash = MakeRequest.new(ctx, api_key).call(query_name: query_name, variables: variables)
          user_errors = resp_hash["data"]["appScriptSet"]["userErrors"]

          return resp_hash["data"]["appScriptSet"]["appScript"]["uuid"] if user_errors.empty?

          if user_errors.any? { |e| e["tag"] == "already_exists_error" }
            raise Errors::ScriptRepushError, uuid
          elsif (e = user_errors.any? { |err| err["tag"] == "configuration_syntax_error" })
            raise Errors::ScriptJsonSyntaxError
          elsif (e = user_errors.find { |err| err["tag"] == "configuration_definition_missing_keys_error" })
            raise Errors::ScriptJsonMissingKeysError, e["message"]
          elsif (e = user_errors.find { |err| err["tag"] == "configuration_definition_invalid_value_error" })
            raise Errors::ScriptJsonInvalidValueError, e["message"]
          elsif (e = user_errors.find do |err|
                   err["tag"] == "configuration_definition_schema_field_missing_keys_error"
                 end)
            raise Errors::ScriptJsonFieldsMissingKeysError, e["message"]
          elsif (e = user_errors.find do |err|
                   err["tag"] == "configuration_definition_schema_field_invalid_value_error"
                 end)
            raise Errors::ScriptJsonFieldsInvalidValueError, e["message"]
          elsif user_errors.find { |err| %w(not_use_msgpack_error schema_version_argument_error).include?(err["tag"]) }
            raise Domain::Errors::MetadataValidationError
          else
            raise Errors::GraphqlError, user_errors
          end
        end

        def get_app_scripts(api_key:, extension_point_type:)
          query_name = "get_app_scripts"
          variables = { appKey: api_key, extensionPointName: extension_point_type.upcase }
          response = MakeRequest.new(ctx, api_key).call(
            query_name: query_name,
            variables: variables
          )
          response["data"]["appScripts"]
        end

        class MakeRequest
          attr_reader :ctx

          def initialize(ctx, api_key)
            @client = ApiClients.default_client(ctx, api_key)
          end

          def call(query_name:, variables: {})
            resp = @client.query(query_name, variables: variables)
            raise_if_graphql_failed(resp)
            resp
          end

          def raise_if_graphql_failed(response)
            raise Errors::EmptyResponseError if response.nil?
            raise Errors::GraphqlError, response["errors"] if response.key?("errors")
          end
        end

        class UploadScript
          attr_reader :ctx

          def initialize(ctx)
            @ctx = ctx
          end

          def call(api_key, script_content)
            apply_module_upload_url(api_key).tap do |url|
              upload(url, script_content)
            end
          end

          private

          def apply_module_upload_url(api_key)
            query_name = "module_upload_url_generate"
            variables = {}
            resp_hash = MakeRequest.new(ctx, api_key).call(query_name: query_name, variables: variables)
            user_errors = resp_hash["data"]["moduleUploadUrlGenerate"]["userErrors"]

            raise Errors::GraphqlError, user_errors if user_errors.any?
            resp_hash["data"]["moduleUploadUrlGenerate"]["url"]
          end

          def upload(url, script_content)
            url = URI(url)

            https = Net::HTTP.new(url.host, url.port)
            https.use_ssl = true

            request = Net::HTTP::Put.new(url)
            request["Content-Type"] = "application/wasm"
            request.body = script_content

            response = https.request(request)
            raise Errors::ScriptUploadError unless response.code == "200"
          end
        end
      end
    end
  end
end
