#
# Copyright:: Copyright (c) 2014-2018, Chef Software Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "chef-dk/policyfile/cookbook_sources"
require "chef-dk/policyfile/cookbook_location_specification"
require "chef-dk/policyfile/storage_config"
require "chef-dk/policyfile/policyfile_location_specification"

require "chef/node/attribute"
require "chef/run_list/run_list_item"

module ChefDK
  module Policyfile
    class DSL

      RUN_LIST_ITEM_COMPONENT = %r{^[.[:alnum:]_-]+$}.freeze

      include StorageConfigDelegation

      attr_writer :name

      attr_reader :errors
      attr_writer :run_list
      attr_writer :default_source
      attr_reader :cookbook_location_specs
      attr_reader :included_policies

      attr_reader :named_run_lists
      attr_reader :node_attributes

      attr_reader :storage_config

      attr_reader :chef_config
      def initialize(storage_config, chef_config: nil)
        @name = nil
        @errors = []
        @run_list = []
        @named_run_lists = {}
        @included_policies = []
        @default_source = [ NullCookbookSource.new ]
        @cookbook_location_specs = {}
        @storage_config = storage_config
        @chef_config = chef_config

        @node_attributes = Chef::Node::Attribute.new({}, {}, {}, {})
      end

      def name(name = nil)
        unless name.nil?
          @name = name
        end
        @name
      end

      def run_list(*run_list_items)
        run_list_items = run_list_items.flatten
        unless run_list_items.empty?
          validate_run_list_items(run_list_items)
          @run_list = run_list_items
        end
        @run_list
      end

      def named_run_list(name, *run_list_items)
        run_list_items = run_list_items.flatten
        unless run_list_items.empty?
          validate_run_list_items(run_list_items, name)
          @named_run_lists[name] = run_list_items
        end
        @named_run_lists[name]
      end

      def default_source(source_type = nil, source_argument = nil, &block)
        return @default_source if source_type.nil?
        case source_type
        when :community, :supermarket
          set_default_community_source(source_argument, &block)
        when :delivery_supermarket
          set_default_delivery_supermarket_source(source_argument, &block)
        when :chef_server
          set_default_chef_server_source(source_argument, &block)
        when :chef_repo
          set_default_chef_repo_source(source_argument, &block)
        when :artifactory
          set_default_artifactory_source(source_argument, &block)
        else
          @errors << "Invalid default_source type '#{source_type.inspect}'"
        end
      end

      def cookbook(name, *version_and_source_opts)
        source_options =
          if version_and_source_opts.last.is_a?(Hash)
            version_and_source_opts.pop
          else
            {}
          end

        constraint = version_and_source_opts.first || ">= 0.0.0"
        spec = CookbookLocationSpecification.new(name, constraint, source_options, storage_config)

        if ( existing_source = @cookbook_location_specs[name] )
          err = "Cookbook '#{name}' assigned to conflicting sources\n\n"
          err << "Previous source: #{existing_source.source_options.inspect}\n"
          err << "Conflicts with: #{source_options.inspect}\n"
          @errors << err
        else
          @cookbook_location_specs[name] = spec
          @errors += spec.errors
        end
      end

      def include_policy(name, source_options = {})
        if ( existing = included_policies.find { |p| p.name == name } )
          err = "Included policy '#{name}' assigned conflicting locations or was already specified\n\n"
          err << "Previous source: #{existing.source_options.inspect}\n"
          err << "Conflicts with: #{source_options.inspect}\n"
          @errors << err
        else
          spec = PolicyfileLocationSpecification.new(name, source_options, storage_config, chef_config)
          included_policies << spec
          @errors += spec.errors
        end
      end

      def default
        @node_attributes.default
      end

      def override
        @node_attributes.override
      end

      def eval_policyfile(policyfile_string)
        @policyfile_filename = policyfile_filename
        instance_eval(policyfile_string, policyfile_filename)
        validate!
        self
      rescue SyntaxError => e
        @errors << "Invalid ruby syntax in policyfile '#{policyfile_filename}':\n\n#{e.message}"
      rescue SignalException, SystemExit
        # allow signal from kill, ctrl-C, etc. to bubble up:
        raise
      rescue Exception => e
        error_message = "Evaluation of policyfile '#{policyfile_filename}' raised an exception\n"
        error_message << "  Exception: #{e.class.name} \"#{e}\"\n\n"
        trace = filtered_bt(policyfile_filename, e)
        error_message << "  Relevant Code:\n"
        error_message << "    #{error_context(policyfile_string, policyfile_filename, e)}\n\n"
        unless trace.empty?
          error_message << "  Backtrace:\n"
          # TODO: need a way to disable filtering
          error_message << filtered_bt(policyfile_filename, e).inject("") { |formatted_trace, line| formatted_trace << "    #{line}\n" }
        end
        @errors << error_message
      end

      private

      def set_default_community_source(source_uri, &block)
        set_default_source(CommunityCookbookSource.new(source_uri, &block))
      end

      def set_default_delivery_supermarket_source(source_uri, &block)
        if source_uri.nil?
          @errors << "You must specify the server's URI when using a default_source :delivery_supermarket"
        else
          set_default_source(DeliverySupermarketSource.new(source_uri, &block))
        end
      end

      def set_default_chef_server_source(source_uri, &block)
        if source_uri.nil?
          @errors << "You must specify the server's URI when using a default_source :chef_server"
        else
          set_default_source(ChefServerCookbookSource.new(source_uri, chef_config: chef_config, &block))
        end
      end

      def set_default_artifactory_source(source_uri, &block)
        if source_uri.nil?
          @errors << "You must specify the server's URI when using a default_source :artifactory"
        else
          set_default_source(ArtifactoryCookbookSource.new(source_uri, chef_config: chef_config, &block))
        end
      end

      def set_default_chef_repo_source(path, &block)
        if path.nil?
          @errors << "You must specify the path to the chef-repo when using a default_source :chef_repo"
        else
          set_default_source(ChefRepoCookbookSource.new(File.expand_path(path, storage_config.relative_paths_root), &block))
        end
      end

      def set_default_source(source)
        @default_source.delete_at(0) if @default_source[0].null?
        @default_source << source
      end

      def validate!
        if @run_list.empty?
          @errors << "Invalid run_list. run_list cannot be empty"
        end

        handle_preferred_cookbooks_conflicts
      end

      def validate_run_list_items(items, run_list_name = nil)
        items.each do |item|

          run_list_desc = run_list_name.nil? ? "Run List Item '#{item}'" : "Named Run List '#{run_list_name}' Item '#{item}'"

          item_name = Chef::RunList::RunListItem.new(item).name
          cookbook, separator, recipe = item_name.partition("::")

          if RUN_LIST_ITEM_COMPONENT.match(cookbook).nil?
            message = "#{run_list_desc} has invalid cookbook name '#{cookbook}'.\nCookbook names can only contain alphanumerics, hyphens, and underscores."

            # Special case when there's only one colon instead of two:
            if cookbook =~ /[^:]:[^:]/
              message << "\nDid you mean '#{item.sub(":", "::")}'?"
            end

            @errors << message
          end
          unless separator.empty?
            # we have a cookbook and recipe
            if RUN_LIST_ITEM_COMPONENT.match(recipe).nil?
              @errors << "#{run_list_desc} has invalid recipe name '#{recipe}'.\nRecipe names can only contain alphanumerics, hyphens, and underscores."
            end
          end
        end
      end

      def handle_preferred_cookbooks_conflicts
        conflicting_source_messages = []
        default_source.combination(2).each do |source_a, source_b|
          conflicting_preferences = source_a.preferred_cookbooks & source_b.preferred_cookbooks
          next if conflicting_preferences.empty?
          conflicting_source_messages << "#{source_a.desc} and #{source_b.desc} are both set as the preferred source for cookbook(s) '#{conflicting_preferences.join(', ')}'"
        end
        unless conflicting_source_messages.empty?
          msg = "Multiple sources are marked as the preferred source for some cookbooks. Only one source can be preferred for a cookbook.\n"
          msg << conflicting_source_messages.join("\n") << "\n"
          @errors << msg
        end
      end

      def error_context(policyfile_string, policyfile_filename, exception)
        if ( line_number_to_show = culprit_line_number(policyfile_filename, exception) )
          code = policyfile_string.lines.to_a[line_number_to_show - 1].strip
          "#{line_number_to_show}: #{code}"
        else
          "Could not find relevant code from backtrace"
        end
      end

      def culprit_line_number(policyfile_filename, exception)
        if ( most_proximate_backtrace_line = filtered_bt(policyfile_filename, exception).first )
          most_proximate_backtrace_line[/^(?:.\:)?[^:]+:([\d]+)/, 1].to_i
        else
          nil
        end
      end

      def filtered_bt(policyfile_filename, exception)
        policyfile_filename_matcher = /^#{Regexp.escape(policyfile_filename)}/
        exception.backtrace.select { |line| line =~ policyfile_filename_matcher }
      end

    end
  end
end
