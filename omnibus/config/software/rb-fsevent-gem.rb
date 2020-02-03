#
# Copyright 2012-2014 Chef Software, Inc.
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

name "rb-fsevent-gem"
default_version "master"

source git: "https://github.com/thibaudgg/rb-fsevent.git"

license "Apache-2.0"
license_file "https://raw.githubusercontent.com/thibaudgg/rb-fsevent/master/LICENSE.txt"

dependency "ruby"

build do
  env = with_standard_compiler_flags(with_embedded_path)
  # Look up active sdk version.
  sdk_ver = `xcrun --sdk macosx --show-sdk-version`.strip
  env["MACOSX_DEPLOYMENT_TARGET"] = sdk_ver

  bundle "install", env: env
  bundle "exec rake replace_exe", env: env, cwd: "#{project_dir}/ext"
  bundle "exec rake install:local", env: env
end
