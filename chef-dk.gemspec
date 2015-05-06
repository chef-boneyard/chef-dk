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

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef-dk/version'

Gem::Specification.new do |gem|
  gem.name          = "chef-dk"
  gem.version       = ChefDK::VERSION
  gem.authors       = [ "Daniel DeLeo", "Lamont Granquist", "Serdar Sutay" ]
  gem.email         = [ "dan@chef.io", "lamont@chef.io", "serdar@chef.io"]
  gem.description   = "A streamlined development and deployment workflow for Chef platform."
  gem.summary       = gem.description
  gem.homepage      = "https://www.chef.io/"

  gem.required_ruby_version = '>= 2.0'

  gem.files = %w(Rakefile LICENSE README.md CONTRIBUTING.md) + Dir.glob("{lib,spec}/**/*", File::FNM_DOTMATCH).reject do |f|
    File.directory?(f)
  end
  gem.executables   = %w( chef )
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "mixlib-cli", "~> 1.5"
  gem.add_dependency "mixlib-shellout", ">= 2.0.0.rc.0", "< 3.0.0"
  gem.add_dependency "ffi-yajl", "~> 1.0"

  gem.add_dependency "chef", "~> 12.0", ">= 12.2.1"

  gem.add_dependency "solve", "~> 1.2"

  gem.add_dependency "cookbook-omnifetch", "~> 0.2"

  gem.add_dependency "diff-lcs", "~> 1.0"
  gem.add_dependency "paint", "~> 1.0"

  gem.add_dependency "chef-provisioning"

  %w(rspec-core rspec-expectations rspec-mocks).each do |dev_gem|
    gem.add_development_dependency dev_gem, "~> 3.0"
  end

end
