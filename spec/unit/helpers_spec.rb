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

require 'spec_helper'
require 'chef-dk/helpers'

describe ChefDK::Helpers do

  let (:helpers) do
    helpers = Class.new do
      include ChefDK::Helpers
    end.new
  end

  describe "chefdk_home" do
    before do
      allow(ENV).to receive(:[]) do |k|
        env[k]
      end
      allow(Chef::Platform).to receive(:windows?).and_return(false)
    end

    context 'when CHEFDK_HOME is set' do
      let(:env) { {'CHEFDK_HOME' => 'foo' } }
      it "returns CHEFDK_HOME" do
        expect(helpers.chefdk_home).to eq(env['CHEFDK_HOME'])
      end
    end

    context 'when CHEFDK_HOME is not set' do
      context 'on windows' do
        before do
          allow(Chef::Platform).to receive(:windows?).and_return(true)
          allow(File).to receive(:join).with(Gem.user_home, '.chefdk').and_return(old_home)
        end

        let(:env) { { 'LOCALAPPDATA' => 'C:\\foo' } }
        let(:old_home) { "C:\\Users\\Vagrant\\.chefdk" }

        context 'when .chefdk exists in Gem.user_home' do
          before do
            allow(File).to receive(:exists?).with(old_home).and_return(true)
          end

          it 'returns the old default home directory' do
            expect(helpers.chefdk_home).to eq(old_home)
          end
        end

        context 'when .chefdk does not exist in Gem.user_home' do
          before do
            allow(File).to receive(:exists?).with(old_home).and_return(false)
          end

          it 'returns the old default home directory' do
            expect(File).to receive(:join).with(env['LOCALAPPDATA'], 'chefdk').and_return('chefdkdefaulthome')
            expect(helpers.chefdk_home).to eq('chefdkdefaulthome')
          end
        end
      end
    end

  end
end
