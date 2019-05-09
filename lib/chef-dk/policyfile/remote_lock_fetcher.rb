#
# Copyright:: Copyright (c) 2019 Chef Software Inc.
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

require "chef-dk/policyfile/local_lock_fetcher"
require "chef-dk/policyfile_lock"
require "chef-dk/exceptions"
require "chef/http"
require "tempfile"

module ChefDK
  module Policyfile

    # A policyfile lock fetcher that can read a lock from a remote location
    # essentially the same as the LocalLockFetcher, it copies the file a locally
    class RemoteLockFetcher < LocalLockFetcher

      # Check the options provided when creating this class for errors
      #
      # @return [Array<String>] A list of errors found
      def errors
        error_messages = []

        [:remote].each do |key|
          error_messages << "include_policy for #{name} is missing key #{key}" unless source_options[key]
        end

        error_messages
      end

      private

      def fetch_lock_data
        FFI_Yajl::Parser.parse(http_client.get(""))
      rescue Net::ProtocolError => e
        if e.respond_to?(:response) && e.response.code.to_s == "404"
          raise ChefDK::PolicyfileLockDownloadError.new("No remote policyfile lock '#{name}' found at #{http_client.url}")
        else
          raise ChefDK::PolicyfileLockDownloadError.new("HTTP error attempting to fetch policyfile lock from #{http_client.url}")
        end
      rescue => e
        raise e
      end

      def http_client
        @http_client ||= Chef::HTTP.new(source_options[:remote])
      end
    end
  end
end
