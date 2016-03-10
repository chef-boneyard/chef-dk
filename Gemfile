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

source 'https://rubygems.org'

gemspec :name => "chef-dk"

# Chef 12.8.1 Gem includes some extra files which can break gem installation on
# windows. For now we are pulling chef from github at the tag as a workaround.
gem "chef", github: "chef", tag: "12.8.1"

group(:dev) do
  gem 'guard'
  gem 'guard-rspec'
  gem 'ruby_gntp'
end
