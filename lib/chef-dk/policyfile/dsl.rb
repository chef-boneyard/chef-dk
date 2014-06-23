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

require 'chef-dk/policyfile/cookbook_source'
require 'chef-dk/policyfile/cookbook_spec'

module ChefDK
  module Policyfile
    class DSL

      attr_reader :errors
      attr_reader :run_list
      attr_reader :default_source
      attr_reader :cookbook_source_overrides

      attr_accessor :policyfile_filename

      def initialize
        @errors = []
        @run_list = []
        @default_source = nil
        @cookbook_source_overrides = {}
        @policyfile_filename = nil
      end

      def run_list(*run_list_items)
        run_list_items = run_list_items.flatten
        @run_list = run_list_items unless run_list_items.empty?
        @run_list
      end

      def default_source(source_type = nil, source_uri = nil)
        return @default_source if source_type.nil?
        case source_type
        when :community
          set_default_community_source(source_uri)
        when :chef_server
          set_default_chef_server_source(source_uri)
        else
          @errors << "Invalid default_source type '#{source_type.inspect}'"
        end
      end

      # TODO: maybe use keyword args?
      # (name, constraint=">= 0.0.0", git: nil, path: nil, github: nil)
      def cookbook(name, *version_and_source_opts)
        source_options =
          if version_and_source_opts.last.is_a?(Hash)
            version_and_source_opts.pop
          else
            {}
          end

        constraint = version_and_source_opts.first || ">= 0.0.0"
        spec = CookbookSpec.new(name, constraint, source_options, policyfile_filename)


        if existing_source = @cookbook_source_overrides[name]
          err = "Cookbook '#{name}' assigned to conflicting sources\n\n"
          err << "Previous source: #{existing_source.source_options.inspect}\n"
          err << "Conflicts with: #{source_options.inspect}\n"
          @errors << err
        else
          @cookbook_source_overrides[name] = spec
        end
      end

      def eval_policyfile(policyfile_string, policyfile_filename)
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
          error_message << filtered_bt(policyfile_filename, e).inject("") { |formatted_trace, line| formatted_trace << "    #{line}" }
          error_message << "\n"
        end
        @errors << error_message
      end

      private

      def set_default_community_source(source_uri)
        @default_source = CommunityCookbookSource.new(source_uri)
      end

      def set_default_chef_server_source(source_uri)
        if source_uri.nil?
          @errors << "You must specify the server's URI when using a default_source :chef_server"
        else
          @default_source = ChefServerCookbookSource.new(source_uri)
        end
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
