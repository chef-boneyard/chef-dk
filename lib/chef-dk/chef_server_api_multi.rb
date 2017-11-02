#
# Copyright:: Copyright (c) 2017 Chef Software Inc.
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

require "chef/server_api"

module ChefDK

  # A wrapper for `Chef::ServerAPI` that supports multi-threading by creating a
  # `Chef::ServerAPI` object per-thread.
  #
  # This is intended to be used for downloading cookbooks from the Chef Server,
  # where the API of the Chef Server requires each file to be downloaded
  # individually.
  #
  # It also configures `Chef::ServerAPI` to enable keepalives by default. To
  # disable them, `keepalives: false` must be set in the options to the
  # constructor.
  class ChefServerAPIMulti

    KEEPALIVES_TRUE = { keepalives: true }.freeze

    attr_reader :url
    attr_reader :opts

    def initialize(url, opts)
      @url = url
      @opts = KEEPALIVES_TRUE.merge(opts)
    end

    def head(*args)
      client_for_thread.head(*args)
    end

    def get(*args)
      client_for_thread.get(*args)
    end

    def put(*args)
      client_for_thread.put(*args)
    end

    def post(*args)
      client_for_thread.post(*args)
    end

    def delete(*args)
      client_for_thread.delete(*args)
    end

    def streaming_request(*args, &block)
      client_for_thread.streaming_request(*args, &block)
    end

    def client_for_thread
      Thread.current[:chef_server_api_multi] ||= Chef::ServerAPI.new(@url, @opts)
    end

  end
end
