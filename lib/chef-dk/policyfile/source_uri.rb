#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
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

require "addressable/uri"
require "chef-dk/exceptions"

module ChefDK
  module Policyfile
    class SourceURI < Addressable::URI
      class << self
        # Returns a URI object based on the parsed string.
        #
        # @param [String, Addressable::URI, #to_str] uri The URI
        # string to parse.  No parsing is performed if the object
        # is already an <code>Addressable::URI</code>.
        #
        # @raise [ChefDK::InvalidPolicyfileSourceURI]
        #
        # @return [ChefDK::Policyfile::SourceURI]
        def parse(uri)
          parsed_uri = super(uri)
          parsed_uri.send(:validate)
          parsed_uri
        rescue TypeError, ArgumentError => ex
          raise ChefDK::InvalidPolicyfileSourceURI.new(uri, ex)
        end
      end

      VALID_SCHEMES = %w{ https http }.freeze

      # @raise [ChefDK::InvalidPolicyfileSourceURI]
      def validate
        super

        unless VALID_SCHEMES.include?(scheme)
          raise InvalidPolicyfileSourceURI.new(self, "invalid URI scheme '#{scheme}'. Valid schemes: #{VALID_SCHEMES}")
        end
      rescue Addressable::URI::InvalidURIError => ex
        raise InvalidPolicyfileSourceURI.new(self, ex)
      end
    end
  end
end
