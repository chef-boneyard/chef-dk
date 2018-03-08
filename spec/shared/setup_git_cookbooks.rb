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

require "chef-dk/helpers"

RSpec.shared_context "setup git cookbooks" do

  include ChefDK::Helpers

  let(:cookbook_pristine_path) do
    File.expand_path("spec/unit/fixtures/dev_cookbooks/bar-cookbook.gitbundle", project_root)
  end

  let(:cookbook_path) { File.join(tempdir, "bar") }

  let(:current_rev) { "dfc68070c47cbf4267be14ea87f80680cb5dafb3" }

  before do
    reset_tempdir
    system_command("git clone #{cookbook_pristine_path} #{cookbook_path}").error!
    system_command("git reset --hard #{current_rev}", cwd: cookbook_path).error!
    system_command("git remote remove origin", cwd: cookbook_path).error!
  end

  after do
    clear_tempdir
  end

end

RSpec.shared_context "setup git cookbook remote" do
  let(:remote_url) { "file://#{tempdir}/bar-cookbook.git" }

  before do
    system_command("git init --bare #{tempdir}/bar-cookbook.git").error!
    system_command("git remote add origin #{remote_url}", cwd: cookbook_path).error!
    system_command("git push -u origin master", cwd: cookbook_path).error!
  end
end
