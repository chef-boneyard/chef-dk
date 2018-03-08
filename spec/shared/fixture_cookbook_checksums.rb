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

RSpec.shared_context "fixture cookbooks checksums" do

  def id_to_dotted(sha1_id)
    major = sha1_id[0...14]
    minor = sha1_id[14...28]
    patch = sha1_id[28..40]
    decimal_integers = [major, minor, patch].map { |hex| hex.to_i(16) }
    decimal_integers.join(".")
  end

  let(:cookbook_foo_cksum) { "467dc855408ce8b74f991c5dc2fd72a6aa369b60" }

  let(:cookbook_foo_cksum_dotted) { id_to_dotted(cookbook_foo_cksum) }

  let(:cookbook_bar_cksum) { "4c538def500b75e744a3af05df66afd04dc3b3c5" }

  let(:cookbook_bar_cksum_dotted) { id_to_dotted(cookbook_bar_cksum) }

  let(:cookbook_baz_cksum) { "5c9063efbc5b5d8acc37024d7383f7dd010ae728" }

  let(:cookbook_baz_cksum_dotted) { id_to_dotted(cookbook_baz_cksum) }

  let(:cookbook_dep_of_bar_cksum) { "a4a6a5e4c6d95a580d291f6415d55b010669feac" }

  let(:cookbook_dep_of_bar_cksum_dotted) { id_to_dotted(cookbook_dep_of_bar_cksum) }

end
