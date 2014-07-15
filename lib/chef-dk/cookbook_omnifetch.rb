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

require 'cookbook-omnifetch'
require 'chef-dk/shell_out'
require 'chef-dk/cookbook_metadata'

# TODO: chef bug. Chef::HTTP::Simple needs to require this itself.
# Fixed in 2ed829e661f9a357fc9a8cdf316c84f077dad7f9 waiting for that to be
# released...
require 'tempfile'
require 'chef/platform/query_helpers' # should be handled by http/simple
require 'chef/http/cookie_manager' # should be handled by http/simple
require 'chef/http/validate_content_length' # should be handled by http/simple
require 'chef/http/simple'

# Configure CookbookOmnifetch's dependency injection settings to use our classes and config.
CookbookOmnifetch.configure do |c|
  c.cache_path = File.expand_path('~/.chefdk/cache')
  c.storage_path = Pathname.new(File.expand_path('~/.chefdk/cache/cookbooks'))
  c.shell_out_class = ChefDK::ShellOut
  c.cached_cookbook_class = ChefDK::CookbookMetadata
end

