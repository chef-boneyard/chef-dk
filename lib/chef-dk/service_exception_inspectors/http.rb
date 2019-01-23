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

require "ffi_yajl"

module ChefDK
  module ServiceExceptionInspectors
    class HTTP

      attr_reader :exception

      def initialize(exception)
        @exception = exception
      end

      def message
        "HTTP #{code} #{response_message}: " + parsed_response_body
      end

      def extended_error_info
        <<~END
          --- REQUEST DATA ----
          #{http_method} #{uri}
          #{request_headers}
          #{req_body}

          --- RESPONSE DATA ---
          #{code} #{response_message}
          #{response_headers}

          #{response_body}

        END
      end

      def response
        exception.response
      end

      def code
        response.code
      end

      def response_message
        response.message
      end

      def response_body
        response.body
      end

      def parsed_response_body
        if response_body && !response_body.empty?
          attempt_error_message_extract
        else
          "(No explanation provided by server)"
        end
      end

      def attempt_error_message_extract
        error_body = FFI_Yajl::Parser.parse(response_body)
        if error_body.respond_to?(:key?) && error_body.key?("error")
          Array(error_body["error"]).join(", ")
        else
          error_body.to_s
        end
      rescue
        response_body
      end

      def response_headers
        headers_s = ""
        response.each_header do |key, value|
          headers_s << key << ": " << value << "\n"
        end
        headers_s
      end

      def request
        exception.chef_rest_request
      end

      def uri
        request.uri.to_s + request.path.to_s
      end

      def http_method
        request.method
      end

      def request_headers
        headers_s = ""
        request.each_header do |key, value|
          headers_s << key << ": " << value << "\n"
        end
        headers_s
      end

      def req_body
        request.body
      end

    end
  end
end
