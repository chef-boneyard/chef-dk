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
  gem.email         = [ "dan@getchef.com", "lamont@getchef.com", "serdar@getchef.com"]
  gem.description   = "A streamlined development and deployment workflow for Chef platform."
  gem.summary       = gem.description
  gem.homepage      = "http://www.getchef.com/"

  gem.required_ruby_version = '>= 2.0'

  gem.files = %w(Rakefile LICENSE README.md CONTRIBUTING.md) + Dir.glob("{lib,spec}/**/*", File::FNM_DOTMATCH).reject do |f|
    File.directory?(f)
  end
  gem.executables   = %w( chef )
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "mixlib-cli", "~> 1.4"
  gem.add_dependency "mixlib-shellout", "~> 1.3"

  # TODO: We really just want to specify "~> 11.12", but this does not pick up
  # prerelease versions. This can be fixed after 11.12.0 is released.
  gem.add_dependency "chef", "~> 11.12.0.alpha.0"

  %w(rspec-core rspec-expectations rspec-mocks).each do |dev_gem|
    gem.add_development_dependency dev_gem, "~> 2.14.0"
  end
  gem.add_development_dependency "pry-debugger"
end
