#
# Copyright 2016 Chef Software, Inc.
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

name "rust"
default_version "2015-10-03"


if mac_os_x?
  host_triple = "apple-darwin"
  md5sum = "0485cb9902a3b3c563c6c6e20b311419"
else
  host_triple = "unknown-linux-gnu"
  md5sum = "eff35d920b30f191b659075a563197a6"
end

relative_path "rust-nightly-x86_64-#{host_triple}"
version "2015-10-03" do
  source url: "https://static.rust-lang.org/dist/#{version}/rust-nightly-x86_64-#{host_triple}.tar.gz",
         md5: md5sum
end

build do
  env = with_standard_compiler_flags(with_embedded_path)
  # Allows us to build with kitchen builders on  virtuablox -
  # due to a bug in virtualbox vboxsf, libgit2 (used by cargo) will
  # encounter failures when using the default vboxsf-mounted
  # /home/vagrant/.cargo location
  env['CARGO_HOME']      = "#{Omnibus::Config.base_dir}/cargo"

  command "./install.sh" \
          " --prefix=#{install_dir}/embedded" \
          " --components=rustc,cargo" \
          " --verbose", env: env
end
