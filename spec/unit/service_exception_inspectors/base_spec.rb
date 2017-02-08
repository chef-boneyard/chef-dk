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

require "spec_helper"
require "chef-dk/service_exception_inspectors/base"

describe ChefDK::ServiceExceptionInspectors::Base do

  let(:message) { "something went wrong, oops" }

  let(:exception) { StandardError.new(message) }

  subject(:inspector) { described_class.new(exception) }

  it "has an exception" do
    expect(inspector.exception).to eq(exception)
  end

  it "gives the exception's message" do
    expect(inspector.message).to eq(message)
  end

  it "has no extended error information" do
    expect(inspector.extended_error_info).to eq("")
  end

end
