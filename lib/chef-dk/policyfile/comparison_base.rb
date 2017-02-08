#
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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

require "ffi_yajl"
require "mixlib/shellout"
require "chef-dk/service_exceptions"

module ChefDK
  module Policyfile
    module ComparisonBase

      class Local

        attr_reader :policyfile_lock_relpath

        def initialize(policyfile_lock_relpath)
          @policyfile_lock_relpath = policyfile_lock_relpath
        end

        def name
          "local:#{policyfile_lock_relpath}"
        end

        def lock
          raise LockfileNotFound, "Expected lockfile at #{policyfile_lock_relpath} does not exist" unless File.exist?(policyfile_lock_relpath)
          raise LockfileNotFound, "Expected lockfile at #{policyfile_lock_relpath} cannot be read" unless File.readable?(policyfile_lock_relpath)
          FFI_Yajl::Parser.parse(IO.read(policyfile_lock_relpath))
        rescue FFI_Yajl::ParseError => e
          raise MalformedLockfile, "Invalid JSON in lockfile at #{policyfile_lock_relpath}:\n  #{e.message}"
        end

      end

      class Git

        attr_reader :ref
        attr_reader :policyfile_lock_relpath

        def initialize(ref, policyfile_lock_relpath)
          @ref = ref
          @policyfile_lock_relpath = policyfile_lock_relpath
        end

        def name
          "git:#{ref}"
        end

        def lock
          git_cmd.run_command
          git_cmd.error!
          FFI_Yajl::Parser.parse(git_cmd.stdout)
        rescue Mixlib::ShellOut::ShellCommandFailed
          raise GitError, "Git command `#{git_cmd_string}` failed with message: #{git_cmd.stderr.chomp}"
        rescue FFI_Yajl::ParseError => e
          raise MalformedLockfile, "Invalid JSON in lockfile at git ref '#{ref}' at path '#{policyfile_lock_relpath}':\n  #{e.message}"
        end

        def git_cmd
          @git_cmd ||= Mixlib::ShellOut.new(git_cmd_string)
        end

        def git_cmd_string
          # Git is a little picky about how we specify the paths, but it looks
          # like we don't need to worry about the relative path to the root of
          # the repo if we give git a leading dot:
          #
          #    git show 6644e6cb2ade90b8aff2ebb44728958fbc939ebf:zero.rb
          #    fatal: Path 'etc/zero.rb' exists, but not 'zero.rb'.
          #    Did you mean '6644e6cb2ade90b8aff2ebb44728958fbc939ebf:etc/zero.rb' aka '6644e6cb2ade90b8aff2ebb44728958fbc939ebf:./zero.rb'?
          #    git show 6644e6cb2ade90b8aff2ebb44728958fbc939ebf:./zero.rb
          #    (works)
          "git show #{ref}:./#{policyfile_lock_relpath}"
        end

      end

      class PolicyGroup

        attr_reader :group
        attr_reader :policy_name
        attr_reader :http_client

        def initialize(group, policy_name, http_client)
          @group = group
          @policy_name = policy_name
          @http_client = http_client
        end

        def name
          "policy_group:#{group}"
        end

        def lock
          http_client.get("policy_groups/#{group}/policies/#{policy_name}")
        rescue Net::ProtocolError => e
          if e.respond_to?(:response) && e.response.code.to_s == "404"
            raise PolicyfileDownloadError.new("No policyfile lock named '#{policy_name}' found in policy_group '#{group}' at #{http_client.url}", e)
          else
            raise PolicyfileDownloadError.new("HTTP error attempting to fetch policyfile lock from #{http_client.url}", e)
          end
        rescue => e
          raise PolicyfileDownloadError.new("Failed to fetch policyfile lock from #{http_client.url}", e)
        end

      end

    end
  end
end
