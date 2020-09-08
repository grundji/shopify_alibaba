# frozen_string_literal: true
require 'project_types/theme/test_helper'

module Theme
  module Commands
    class PushTest < MiniTest::Test
      include TestHelpers::FakeUI

      def test_can_push_entire_theme
        context = ShopifyCli::Context.new
        Themekit.expects(:ensure_themekit_installed).with(context)
        Themekit.expects(:push).with(context, files: [], flags: [], remove: nil).returns(true)
        context.expects(:done).with(context.message('theme.push.info.pushed', context.root))

        Theme::Commands::Push.new(context).call([], 'push')
      end

      def test_can_push_individual_files
        context = ShopifyCli::Context.new
        Themekit.expects(:ensure_themekit_installed).with(context)
        Themekit.expects(:push)
          .with(context, files: ['file.liquid', 'another_file.liquid'], flags: [], remove: nil)
          .returns(true)
        context.expects(:done).with(context.message('theme.push.info.pushed', context.root))

        Theme::Commands::Push.new(context).call(['file.liquid', 'another_file.liquid'], 'push')
      end

      def test_can_remove_files
        context = ShopifyCli::Context.new
        Themekit.expects(:ensure_themekit_installed).with(context)
        Themekit.expects(:push)
          .with(context, files: ['file.liquid', 'another_file.liquid'], flags: [], remove: true)
          .returns(true)
        context.expects(:done).with(context.message('theme.push.info.removed', context.root))

        command = Theme::Commands::Push.new(context)
        command.options.flags['remove'] = true
        command.call(['file.liquid', 'another_file.liquid'], 'push')
      end

      def test_can_add_flags
        context = ShopifyCli::Context.new
        Themekit.expects(:ensure_themekit_installed).with(context)
        Themekit.expects(:push)
          .with(context, files: ['file.liquid', 'another_file.liquid'], flags: ['--nodelete'], remove: nil)
          .returns(true)
        context.expects(:done).with(context.message('theme.push.info.pushed', context.root))

        command = Theme::Commands::Push.new(context)
        command.options.flags['nodelete'] = true
        command.call(['file.liquid', 'another_file.liquid'], 'push')
      end

      def test_aborts_if_push_fails
        context = ShopifyCli::Context.new
        Themekit.expects(:ensure_themekit_installed).with(context)
        Themekit.expects(:push).with(context, files: [], flags: [], remove: nil).returns(false)

        assert_raises CLI::Kit::Abort do
          Theme::Commands::Push.new(context).call([], 'push')
        end
      end
    end
  end
end
