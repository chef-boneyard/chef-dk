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

require "mixlib/shellout"
require "chef-dk/exceptions"

module ChefDK
  module Helpers
    extend self

    #
    # Runs given commands using mixlib-shellout
    #
    def system_command(*command_args)
      cmd = Mixlib::ShellOut.new(*command_args)
      cmd.run_command
      cmd
    end

    def err(message)
      stderr.print("#{message}\n")
    end

    def msg(message)
      stdout.print("#{message}\n")
    end

    def stdout
      $stdout
    end

    def stderr
      $stderr
    end

    #
    # Locates the omnibus directories
    #

    def omnibus_install?
      File.exist?(omnibus_chefdk_location)
    end

    def omnibus_root
      @omnibus_root ||= omnibus_expand_path(expected_omnibus_root)
    end

    def omnibus_apps_dir
      @ominbus_apps_dir ||= omnibus_expand_path(omnibus_root, "embedded", "apps")
    end

    def omnibus_bin_dir
      @omnibus_bin_dir ||= omnibus_expand_path(omnibus_root, "bin")
    end

    def omnibus_embedded_bin_dir
      @omnibus_embedded_bin_dir ||= omnibus_expand_path(omnibus_root, "embedded", "bin")
    end

    def omnibus_chefdk_location
      @omnibus_chefdk_location ||= File.expand_path("embedded/apps/chef-dk", expected_omnibus_root)
    end

    def chefdk_home
      @chefdk_home ||= begin
                         chefdk_home_set = !([nil, ""].include? ENV["CHEFDK_HOME"])
                         if chefdk_home_set
                           ENV["CHEFDK_HOME"]
                         else
                           default_chefdk_home
                         end
                       end
    end

    # Returns the directory that contains our main symlinks.
    # On Mac we place all of our symlinks under /usr/local/bin on other
    # platforms they are under /usr/bin
    def usr_bin_prefix
      @usr_bin_prefix ||= os_x? ? "/usr/local/bin" : "/usr/bin"
    end

    # Returns the full path to the given command under usr_bin_prefix
    def usr_bin_path(command)
      File.join(usr_bin_prefix, command)
    end

    # Unix users do not want git on their path if they already have it installed.
    # Because we put `embedded/bin` on the path we must move the git binaries
    # somewhere else that we can append to the end of the path.
    # This is only a temporary solution - see https://github.com/chef/chef-dk/issues/854
    # for a better proposed solution.
    def git_bin_dir
      @git_bin_dir ||= File.expand_path(File.join(omnibus_root, "gitbin"))
    end

    # In our Windows ChefDK omnibus package we include Git For Windows, which
    # has a bunch of helpful unix utilties (like ssh, scp, etc.) bundled with it
    def git_windows_bin_dir
      @git_windows_bin_dir ||= File.expand_path(File.join(omnibus_root, "embedded", "git", "usr", "bin"))
    end

    #
    # environment vars for omnibus
    #
    def omnibus_env
      @omnibus_env ||=
        begin
          user_bin_dir = File.expand_path(File.join(Gem.user_dir, "bin"))
          path = [ omnibus_bin_dir, user_bin_dir, omnibus_embedded_bin_dir, ENV["PATH"] ]
          path << git_bin_dir if Dir.exists?(git_bin_dir)
          path << git_windows_bin_dir if Dir.exists?(git_windows_bin_dir)
          {
            "PATH" => path.join(File::PATH_SEPARATOR),
            "GEM_ROOT" => Gem.default_dir,
            "GEM_HOME" => Gem.user_dir,
            "GEM_PATH" => Gem.path.join(File::PATH_SEPARATOR),
          }
        end
    end

    private

    def omnibus_expand_path(*paths)
      dir = File.expand_path(File.join(paths))
      raise OmnibusInstallNotFound.new() unless dir && File.directory?(dir)
      dir
    end

    def expected_omnibus_root
      File.expand_path(File.join(Gem.ruby, "..", "..", ".."))
    end

    def default_chefdk_home
      if Chef::Platform.windows?
        File.join(ENV["LOCALAPPDATA"], "chefdk")
      else
        File.expand_path("~/.chefdk")
      end
    end

    # Open a file. By default, the mode is for read+write,
    # and binary so that windows writes out what we tell it,
    # as this is the most common case we have.
    def with_file(path, mode = "wb+", &block)
      File.open(path, mode, &block)
    end

    #@api private
    # This method resets all the instance variables used. It
    # should only be used for testing
    def reset!
      instance_variables.each do |ivar|
        instance_variable_set(ivar, nil)
      end
    end

    # Returns true if we are on Mac OS X. Otherwise false
    def os_x?
      !!(RUBY_PLATFORM =~ /darwin/)
    end
  end
end
