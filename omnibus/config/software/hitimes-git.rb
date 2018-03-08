# Copyright 2012-2018, Chef Software Inc.
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

name "hitimes-git"

license "ISC"
license_file "https://github.com/copiousfreetime/hitimes/blob/master/LICENSE"
skip_transitive_dependency_licensing true

dependency "ruby"

dependency "rubygems"
dependency "bundler"

source git: "https://github.com/copiousfreetime/hitimes"
default_version "master"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  gemfile = windows? ? "hitimes-1.2.4-x86-mingw32.gem" : "hitimes-1.2.4.gem"

  rake "gem", env: env

  gem "install pkg/#{gemfile}", env: env
end
