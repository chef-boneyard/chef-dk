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

require 'mixlib/shellout'
require 'chef-dk/exceptions'

module ChefDK
  module Helpers

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
      @omnibus_chefdk_location ||= File.expand_path('embedded/apps/chef-dk', expected_omnibus_root)
    end

    private

    def omnibus_expand_path(*paths)
      dir = File.expand_path(File.join(paths))
      raise OmnibusInstallNotFound.new() unless ( dir and File.directory?(dir) )
      dir
    end

    def expected_omnibus_root
      File.expand_path(File.join(Gem.ruby, "..", "..", ".."))
    end

    #
    # environment vars for omnibus
    #

    def omnibus_env
      @omnibus_env ||=
        begin
          user_bin_dir = File.expand_path(File.join(Gem.user_dir, 'bin'))
          {
            'PATH' => [ omnibus_bin_dir, user_bin_dir, omnibus_embedded_bin_dir, ENV['PATH'] ].join(File::PATH_SEPARATOR),
            'GEM_ROOT' => Gem.default_dir.inspect,
            'GEM_HOME' => Gem.user_dir,
            'GEM_PATH' => Gem.path.join(':'),
          }
        end
    end

    # Open a file. By default, the mode is for read+write,
    # and binary so that windows writes out what we tell it,
    # as this is the most common case we have.
    def with_file(path, mode='wb+', &block)
      File.open(path, mode, &block)
    end
  end
end
