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

require 'chef-dk/exceptions'
require 'chef-dk/helpers'

module ChefDK
  class ComponentTest

    class NullTestResult
      def exitstatus
        0
      end

      def stdout
        ""
      end

      def stderr
        ""
      end
    end

    DEFAULT_TEST = lambda { |context| NullTestResult.new }

    include Helpers

    attr_accessor :base_dir
    attr_accessor :gem_base_dir

    attr_writer :omnibus_root

    attr_reader :name

    def initialize(name)
      @name = name
      @unit_test = DEFAULT_TEST
      @integration_test = DEFAULT_TEST
      @smoke_test = DEFAULT_TEST
    end

    def unit_test(&test_block)
      @unit_test = test_block
    end

    def run_unit_test
      instance_eval(&@unit_test)
    end

    def integration_test(&test_block)
      @integration_test = test_block
    end

    def run_integration_test
      instance_eval(&@integration_test)
    end

    def smoke_test(&test_block)
      @smoke_test = test_block
    end

    def run_smoke_test
      instance_eval(&@smoke_test)
    end

    def sh(command, options={})
      combined_opts = default_command_options.merge(options)

      # Env is a hash, so it needs to be merged separately
      if options.key?(:env)
        combined_opts[:env] = default_command_options[:env].merge(options[:env])
      end
      system_command(command, combined_opts)
    end

    def run_in_tmpdir(command, options={})
      tmpdir do |dir|
        options[:cwd] = dir
        sh(command, options)
      end
    end

    def tmpdir
      Dir.mktmpdir do |tmpdir|
        yield tmpdir
      end
    end

    def assert_present!
      unless File.exists?( component_path )
        raise MissingComponentError.new(name)
      end
    end

    def default_command_options
      {
        :cwd => component_path,
        :env => {
          # Add the embedded/bin to the PATH so that bundle executable can
          # be found while running the tests.
          path_variable_key => omnibus_path
        },
        :timeout => 3600
      }
    end

    def component_path
      if base_dir
        File.join(omnibus_apps_dir, base_dir)
      elsif gem_base_dir
        gem_base_dir
      else
        raise "`base_dir` or `gem_base_dir` must be defined for component `#{name}`"
      end
    end

    def gem_base_dir=(gem_name)
      @gem_base_dir ||= Gem::Specification::find_by_name(gem_name).gem_dir
    end

    def omnibus_root
      @omnibus_root or raise "`omnibus_root` must be set before running tests"
    end

    def omnibus_path
      [omnibus_bin_dir, omnibus_embedded_bin_dir, ENV['PATH']].join(File::PATH_SEPARATOR)
    end

    def path_variable_key
      ENV.keys.grep(/\Apath\Z/i).first
    end

  end
end

