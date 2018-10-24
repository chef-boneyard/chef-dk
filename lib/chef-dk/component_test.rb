#
# Copyright:: Copyright (c) 2014-2018 Chef Software Inc.
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

require "chef-dk/exceptions"
require "chef-dk/helpers"

# https://github.com/bundler/bundler/issues/4368
# As of rubygems 2.6.2, Rubygems will call Bundler::SpecSet#size, which does
# not exist as of Bundler 1.11.2.
#
# `#size` and `#length` should be synonyms in idiomatic ruby so we alias to
# make bundler and rubygems play nicely.
if Object.const_defined?(:Bundler) &&
    Bundler.const_defined?(:SpecSet) &&
    Bundler::SpecSet.instance_methods.include?(:length) &&
    !Bundler::SpecSet.instance_methods.include?(:size)

  module Bundler
    class SpecSet

      alias_method :size, :length

    end
  end

end

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

    attr_writer :omnibus_root

    attr_reader :name

    def initialize(name)
      @name = name
      @unit_test = DEFAULT_TEST
      @integration_test = DEFAULT_TEST
      @smoke_test = DEFAULT_TEST
      @base_dir = nil
      @gem_name_for_base_dir = nil
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

    def bin(binary)
      File.join(omnibus_bin_dir, binary)
    end

    def embedded_bin(binary)
      File.join(omnibus_embedded_bin_dir, binary)
    end

    def sh(command, options = {})
      combined_opts = default_command_options.merge(options)

      # Env is a hash, so it needs to be merged separately
      if options.key?(:env)
        combined_opts[:env] = default_command_options[:env].merge(options[:env])
      end
      system_command(command, combined_opts)
    end

    # Just like #sh but raises an error if the the command returns an
    # unexpected exit code.
    #
    # Most verification steps just run a single command, then
    # ChefDK::Command::Verify#invoke_tests handles the results by inspecting
    # the return value of the test block. For tests that run a lot of commands,
    # this is inconvenient so you can use #sh! instead.
    def sh!(*args)
      sh(*args).tap { |result| result.error! }
    end

    # Run a command, if the command returns zero, raise an error,
    # otherwise, if it returns non-zero or doesn't exist,
    # return a passing command so that the test parser doesn't
    # crash.
    def fail_if_exit_zero(cmd_string, failure_string = "")
      result = sh(cmd_string)
      if result.status.exitstatus == 0
        raise failure_string
      else
        sh("true")
      end
    rescue Errno::ENOENT
      sh("true")
    end

    def nix_platform_native_bin_dir
      if /sunos|solaris/ =~ RUBY_PLATFORM
        "/opt/local/bin"
      elsif /darwin/ =~ RUBY_PLATFORM
        "/usr/local/bin"
      else
        "/usr/bin"
      end
    end

    def run_in_tmpdir(command, options = {})
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
      unless File.exist?( component_path )
        raise MissingComponentError.new(name, "Could not find #{component_path}")
      end
    rescue Gem::LoadError => e
      raise MissingComponentError.new(name, e)
    end

    def default_command_options
      {
        cwd: component_path,
        env: {
          # Add the embedded/bin to the PATH so that bundle executable can
          # be found while running the tests.
          path_variable_key => omnibus_path,
        },
        timeout: 3600,
      }
    end

    def component_path
      if base_dir
        File.join(omnibus_root, base_dir)
      elsif gem_base_dir
        gem_base_dir
      else
        raise "`base_dir` or `gem_base_dir` must be defined for component `#{name}`"
      end
    end

    def gem_base_dir
      return nil if @gem_name_for_base_dir.nil?
      # There is no way to say "give me the latest prerelease OR normal version of this gem.
      # So we first ask if there is a normal version, and if there is not, we ask if there
      # is a prerelease version.  ">= 0.a" is how we ask for a prerelease version, because a
      # prerelease version is defined as "any version with a letter in it."
      gem = Gem::Specification.find_by_name(@gem_name_for_base_dir)
      gem ||= Gem::Specification.find_by_name(@gem_name_for_base_dir, ">= 0.a")
      gem.gem_dir
    end

    def gem_base_dir=(gem_name)
      @gem_name_for_base_dir = gem_name
    end

    def omnibus_root
      @omnibus_root || raise("`omnibus_root` must be set before running tests")
    end

    def omnibus_path
      [omnibus_bin_dir, omnibus_embedded_bin_dir, ENV["PATH"]].join(File::PATH_SEPARATOR)
    end

    def path_variable_key
      ENV.keys.grep(/\Apath\Z/i).first
    end

  end
end
