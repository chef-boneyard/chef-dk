#
# Copyright:: Copyright (c) 2015-2018, Chef Software Inc.
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

require "chef-dk/ui"

module ChefDK
  class Pager

    attr_reader :pager_pid

    def initialize(enable_pager: true)
      @enable_pager = enable_pager
      @pipe = nil
    end

    def pager_enabled?
      !!(@enable_pager && have_tty? && env["PAGER"])
    end

    def ui
      @ui ||=
        if pager_enabled?
          UI.new(out: parent_stdout)
        else
          UI.new
        end
    end

    def with_pager
      start
      begin
        yield self
      ensure
        wait
      end
    end

    def start
      return false unless pager_enabled?

      # Ignore CTRL-C because it can cause the parent to die before the
      # pager which causes wonky behavior in the terminal
      Kernel.trap(:INT, "IGNORE")

      @pager_pid = Process.spawn(pager_env, env["PAGER"], in: child_stdin)

      child_stdin.close
    end

    def wait
      return false unless pager_enabled?

      # Sends EOF to the PAGER
      parent_stdout.close
      # wait or else we'd kill the pager when we exit
      Process.waitpid(pager_pid)
    end

    # @api private
    # This is just public so we can stub it for testing
    def env
      ENV
    end

    # @api private
    # This is just public so we can stub it for testing
    def have_tty?
      $stdout.tty?
    end

    private

    def child_stdin
      pipe[0]
    end

    def parent_stdout
      pipe[1]
    end

    def pipe
      @pipe ||= IO.pipe
    end

    def pager_env
      { "LESS" => "-FRX", "LV" => "-c" }
    end

  end
end
