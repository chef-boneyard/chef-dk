#
# Copyright:: Copyright (c) 2014 Chef Software Inc.
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

require 'chef-dk/policyfile/cookbook_sources'
require 'chef-dk/policyfile/cookbook_location_specification'
require 'chef-dk/policyfile/storage_config'

require 'chef/node/attribute'

module ChefDK
  module Policyfile
    class DSL

      include StorageConfigDelegation

      attr_writer :name

      attr_reader :errors
      attr_reader :run_list
      attr_reader :default_source
      attr_reader :cookbook_location_specs

      attr_reader :named_run_lists
      attr_reader :node_attributes

      attr_reader :storage_config

      def initialize(storage_config)
        @name = nil
        @errors = []
        @run_list = []
        @named_run_lists = {}
        @default_source = [ NullCookbookSource.new ]
        @cookbook_location_specs = {}
        @storage_config = storage_config

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
        @run_list = run_list_items unless run_list_items.empty?
        @run_list
      end

      def named_run_list(name, *run_list_items)
        @named_run_lists[name] = run_list_items.flatten
      end

      def default_source(source_type = nil, source_argument = nil)
        return @default_source if source_type.nil?
        case source_type
        when :community, :supermarket
          set_default_community_source(source_argument)
        when :chef_server
          set_default_chef_server_source(source_argument)
        when :chef_repo
          set_default_chef_repo_source(source_argument)
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


        if existing_source = @cookbook_location_specs[name]
          err = "Cookbook '#{name}' assigned to conflicting sources\n\n"
          err << "Previous source: #{existing_source.source_options.inspect}\n"
          err << "Conflicts with: #{source_options.inspect}\n"
          @errors << err
        else
          @cookbook_location_specs[name] = spec
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
        error_message << "  Exception: #{e.class.name} \"#{e.to_s}\"\n\n"
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

      def set_default_community_source(source_uri)
        set_default_source(CommunityCookbookSource.new(source_uri))
      end

      def set_default_chef_server_source(source_uri)
        if source_uri.nil?
          @errors << "You must specify the server's URI when using a default_source :chef_server"
        else
          set_default_source(ChefServerCookbookSource.new(source_uri))
        end
      end

      def set_default_chef_repo_source(path)
        if path.nil?
          @errors << "You must specify the path to the chef-repo when using a default_source :chef_repo"
        else
          set_default_source(ChefRepoCookbookSource.new(File.expand_path(path, storage_config.relative_paths_root)))
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
      end

      def error_context(policyfile_string, policyfile_filename, exception)
        if line_number_to_show = culprit_line_number(policyfile_filename, exception)
          code = policyfile_string.lines.to_a[line_number_to_show - 1].strip
          "#{line_number_to_show}: #{code}"
        else
          "Could not find relevant code from backtrace"
        end
      end

      def culprit_line_number(policyfile_filename, exception)
        if most_proximate_backtrace_line = filtered_bt(policyfile_filename, exception).first
          most_proximate_backtrace_line[/^(?:.\:)?[^:]+:([\d]+)/,1].to_i
        else
          nil
        end
      end

      def filtered_bt(policyfile_filename, exception)
        policyfile_filename_matcher = /^#{Regexp.escape(policyfile_filename)}/
        exception.backtrace.select {|line| line =~ policyfile_filename_matcher }
      end

    end
  end
end
