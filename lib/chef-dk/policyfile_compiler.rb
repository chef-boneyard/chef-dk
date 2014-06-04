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

require 'chef/run_list/run_list_item'

module ChefDK
  class PolicyfileCompiler

    class CommunityCookbookSource

      attr_reader :uri

      def initialize(uri = nil)
        @uri = uri || "https://api.berkshelf.com"
      end

      def ==(other)
        other.kind_of?(self.class) && other.uri == uri
      end
    end

    class ChefServerCookbookSource

      attr_reader :uri

      def initialize(uri)
        @uri = uri
      end

      def ==(other)
        other.kind_of?(self.class) && other.uri == uri
      end
    end

    DEFAULT_DEMAND_CONSTRAINT = '>= 0.0.0'.freeze

    # Cookbooks from these sources lock that cookbook to exactly one version
    SOURCE_TYPES_WITH_FIXED_VERSIONS = [:git, :path].freeze

    def self.evaluate(policyfile_string, policyfile_filename)
      compiler = new(policyfile_string, policyfile_filename)
      compiler.evaluate!
      compiler
    end

    attr_reader :errors
    attr_reader :cookbook_source_overrides

    attr_writer :run_list

    def initialize(policyfile_string, policyfile_filename)
      @policyfile_string = policyfile_string
      @policyfile_filename = policyfile_filename
      @errors = []
      @run_list = []
      @default_source = nil
      @cookbook_source_overrides = {}
    end

    ##
    # DSL Methods
    ##

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

    def cookbook(name, source_opts={})
      if existing_source = @cookbook_source_overrides[name]
        err = "Cookbook '#{name}' assigned to conflicting sources\n\n"
        err << "Previous source: #{existing_source.inspect}\n"
        err << "Conflicts with: #{source_opts.inspect}\n"
        @errors << err
      else
        @cookbook_source_overrides[name] = source_opts
      end
    end

    ##
    # Compilation Methods
    ##

    def graph_demands
      cookbooks_in_run_list.map do |cookbook_name, version_constraint|
        [ cookbook_name, version_constraint_for(cookbook_name) ]
      end
    end

    def artifacts_graph
      remote_artifacts_graph.merge(local_artifacts_graph)
    end

    def local_artifacts_graph
      cookbooks_in_run_list.inject({}) do |local_artifacts, cookbook_name|
        if cookbook_version_fixed?(cookbook_name)
          local_artifacts[cookbook_name] = cache_manager.cookbook_dependencies(cookbook_name)
        end
        local_artifacts
      end
    end

    def remote_artifacts_graph
      cache_manager.universe_graph
    end

    def version_constraint_for(cookbook_name)
      if cookbook_version_fixed?(cookbook_name)
        version = cache_manager.cookbook_version(cookbook_name)
        "= #{version}"
      else
        DEFAULT_DEMAND_CONSTRAINT
      end
    end

    def cookbook_version_fixed?(cookbook_name)
      if source_options = cookbook_source_overrides[cookbook_name]
        SOURCE_TYPES_WITH_FIXED_VERSIONS.any? { |type| source_options.key?(type) }
      else
        false
      end
    end

    def cache_manager
      raise "TODO"
    end

    def run_list_graph_demands
      cookbooks_in_run_list.map {|cookbook_name| [cookbook_name, DEFAULT_DEMAND_CONSTRAINT] }
    end

    def cookbooks_in_run_list
      run_list.map {|item_spec| Chef::RunList::RunListItem.new(item_spec).name }
    end

    def evaluate!
      instance_eval(@policyfile_string, @policyfile_filename)
      validate!
    rescue SyntaxError => e
      @errors << "Invalid ruby syntax in policyfile '#{@policyfile_filename}':\n\n#{e.message}"
    rescue SignalException, SystemExit
      # allow signal from kill, ctrl-C, etc. to bubble up:
      raise
    rescue Exception => e
      error_message = "Evaluation of policyfile '#{@policyfile_filename}' raised an exception\n"
      error_message << "  Exception: #{e.class.name} \"#{e.to_s}\"\n\n"
      trace = filtered_bt(e)
      error_message << "  Relevant Code:\n"
      error_message << "    #{error_context(e)}\n\n"
      unless trace.empty?
        error_message << "  Backtrace:\n"
        error_message << filtered_bt(e).inject("") { |formatted_trace, line| formatted_trace << "    #{line}" }
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

    def error_context(exception)
      if line_number_to_show = culprit_line_number(exception)
        code = @policyfile_string.lines.to_a[line_number_to_show - 1].strip
        "#{line_number_to_show}: #{code}"
      else
        "Could not find relevant code from backtrace"
      end
    end

    def culprit_line_number(exception)
      if most_proximate_backtrace_line = filtered_bt(exception).first
        most_proximate_backtrace_line[/^(?:.\:)?[^:]+:([\d]+)/,1].to_i
      else
        nil
      end
    end

    def filtered_bt(exception)
      policyfile_filename_matcher = /^#{Regexp.escape(@policyfile_filename)}/
      exception.backtrace.select {|line| line =~ policyfile_filename_matcher }
    end

  end
end
