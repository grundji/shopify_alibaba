require 'shopify_cli'

module ShopifyCli
  module Commands
    class Create
      class Project < ShopifyCli::SubCommand
        options do |parser, flags|
          parser.on('--title=TITLE') { |t| title[:title] = t }
          parser.on('--type=TYPE') { |t| flags[:type] = t.downcase.to_sym }
          parser.on('--app_url=APPURL') { |url| flags[:app_url] = url }
          parser.on('--organization_id=ID') { |url| flags[:organization_id] = url }
          parser.on('--shop_domain=MYSHOPIFYDOMAIN') { |url| flags[:shop_domain] = url }
        end

        def call(args, _name)
<<<<<<< HEAD
          form = Forms::CreateApp.ask(@ctx, args, options.flags)
          return @ctx.puts(self.class.help) if form.nil?

          AppTypeRegistry.check_dependencies(form.type, @ctx)
          AppTypeRegistry.build(form.type, form.name, @ctx)
          ShopifyCli::Project.write(@ctx, form.type)

          api_client = Tasks::CreateApiClient.call(
            @ctx,
            org_id: form.organization_id,
            title: form.title,
            app_url: form.app_url,
          )

          Helpers::EnvFile.new(
            api_key: api_client["apiKey"],
            secret: api_client["apiSecretKeys"].first["secret"],
            shop: form.shop_domain,
            scopes: 'write_products,write_customers,write_draft_orders',
          ).write(@ctx, app_type: ShopifyCli::AppTypeRegistry[form.type])
=======
          name = args.first
          flag = options.flags[:type]
          unless name
            @ctx.puts(self.class.help)
            return
          end
          name = args[1]

          app_type = CLI::UI::Prompt.ask('What type of app project would you like to create?') do |handler|
            AppTypeRegistry.each do |identifier, type|
              handler.option(type.description) { identifier }
            end
          end

          ShopifyCli::Tasks::Tunnel.call(@ctx)

          AppTypeRegistry.check_dependencies(app_type, @ctx)

          AppTypeRegistry.build(app_type, name, @ctx)
          ShopifyCli::Project.write(@ctx, app_type)
          @ctx.puts("{{*}} Whitelist your development URLs in the Partner Dashboard:
          {{underline:https://github.com/Shopify/shopify-app-cli#whitelisting-app-redirection-urls}}")
>>>>>>> 182c6f8... add graphql files
        end

        def self.help
          <<~HELP
            Create a new app project.
              Usage: {{command:#{ShopifyCli::TOOL_NAME} create project <appname>}}
          HELP
        end
      end
    end
  end
end
