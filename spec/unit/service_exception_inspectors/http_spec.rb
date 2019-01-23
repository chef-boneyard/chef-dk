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

require "spec_helper"
require "net/http"
require "chef/monkey_patches/net_http"
require "chef-dk/service_exception_inspectors/http"

describe ChefDK::ServiceExceptionInspectors::HTTP do

  let(:message) { "something went wrong, oops" }

  let(:response_body) { "" }

  let(:request_headers) do
    {
      "content-type" => "application/json",
      "accept" => "application/json",
    }
  end

  let(:request_body) { "this is the request" }

  let(:request) do
    r = instance_double(Net::HTTP::Post,
                        method: "POST",
                        uri: nil,
                        path: "/organizations/chef-oss-dev/cookbooks",
                        body: request_body)
    stub = allow(r).to(receive(:each_header))
    request_headers.each { |k, v| stub.and_yield(k, v) }
    r
  end

  let(:response_headers) do
    {
      "server" => "ngx_openresty",
      "date" => "Wed, 29 Oct 2014 22:27:47 GMT",
    }
  end

  let(:response) do
    r = instance_double(Net::HTTPClientError,
                    code: "400",
                    message: "Bad Request",
                    body: response_body)
    stub = allow(r).to(receive(:each_header))
    response_headers.each { |k, v| stub.and_yield(k, v) }
    r
  end

  let(:exception) do
    Net::HTTPServerException.new(message, response).tap { |e| e.chef_rest_request = request }
  end

  subject(:inspector) { described_class.new(exception) }

  it "has an exception" do
    expect(inspector.exception).to eq(exception)
  end

  context "with a string response body" do

    let(:response_body) { "No sir, I didn't like it" }

    it "gives a customized exception message including the server response" do
      expect(inspector.message).to eq("HTTP 400 Bad Request: No sir, I didn't like it")
    end

  end

  context "with an empty response body" do

    let(:response_body) { "" }

    it "gives a customized exception message including the server response" do
      expect(inspector.message).to eq("HTTP 400 Bad Request: (No explanation provided by server)")
    end

  end

  context "with a JSON response body in the standard Chef Server format" do

    let(:response_body) { %q[{"error":["Field 'name' invalid"]}] }

    it "gives a customized exception message including the server response" do
      expect(inspector.message).to eq("HTTP 400 Bad Request: Field 'name' invalid")
    end

  end

  describe "showing the request and response in extended error info" do

    let(:response_body) { "this is the response" }

    it "shows the request in a format similar to HTTP messages" do
      expected_request_string = <<~E
        --- REQUEST DATA ----
        POST /organizations/chef-oss-dev/cookbooks
        content-type: application/json
        accept: application/json

        this is the request

      E
      expect(inspector.extended_error_info).to include(expected_request_string)
    end

    it "shows the response in a format similar to HTTP messages" do
      expected_response_string = <<~E
        --- RESPONSE DATA ---
        400 Bad Request
        server: ngx_openresty
        date: Wed, 29 Oct 2014 22:27:47 GMT


        this is the response
      E
      expect(inspector.extended_error_info).to include(expected_response_string)
    end

  end

end
