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

require "spec_helper"
require "chef-dk/policyfile/differ"

describe ChefDK::Policyfile::Differ do

  let(:old_lock_json) do
    <<~E
      {
        "revision_id": "cf4b8a020bdc1ba6914093a8a07a5514cce8a3a2979a967b1f32ea704a61785b",
        "name": "jenkins",
        "run_list": [
          "recipe[java::default]",
          "recipe[jenkins::master]",
          "recipe[policyfile_demo::whatever]",
          "recipe[policyfile_demo::default]"
        ],
        "named_run_lists": {
          "update_jenkins": [
            "recipe[jenkins::master]",
            "recipe[policyfile_demo::default]"
          ]
        },
        "cookbook_locks": {
          "policyfile_demo": {
            "version": "0.1.0",
            "identifier": "ea96c99da079db9ff3cb22601638fabd5df49599",
            "dotted_decimal_identifier": "66030937227426267.45022575077627448.275691232073113",
            "source": "cookbooks/policyfile_demo",
            "cache_key": null,
            "scm_info": {
              "scm": "git",
              "remote": "git@github.com:danielsdeleo/policyfile-jenkins-demo.git",
              "revision": "6f92fe8f24fd953a1c40ebb1d7cdb2a4fbbf4d4d",
              "working_tree_clean": false,
              "published": true,
              "synchronized_remote_branches": [
                "mine/master"
              ]
            },
            "source_options": {
              "path": "cookbooks/policyfile_demo"
            }
          },
          "apt": {
            "version": "2.7.0",
            "identifier": "16c57abbd056543f7d5a15dabbb03261024a9c5e",
            "dotted_decimal_identifier": "6409580415309396.17870749399956400.55392231660638",
            "cache_key": "apt-2.7.0-supermarket.chef.io",
            "origin": "https://supermarket.chef.io/api/v1/cookbooks/apt/versions/2.7.0/download",
            "source_options": {
              "artifactserver": "https://supermarket.chef.io/api/v1/cookbooks/apt/versions/2.7.0/download",
              "version": "2.7.0"
            }
          },
          "java": {
            "version": "1.31.0",
            "identifier": "9178a38ad3e3baa55b49c1b8d9f4bf6a43dbc358",
            "dotted_decimal_identifier": "40946515427189690.46543743498115572.210463125914456",
            "cache_key": "java-1.31.0-supermarket.chef.io",
            "origin": "https://supermarket.chef.io/api/v1/cookbooks/java/versions/1.31.0/download",
            "source_options": {
              "artifactserver": "https://supermarket.chef.io/api/v1/cookbooks/java/versions/1.31.0/download",
              "version": "1.31.0"
            }
          },
          "jenkins": {
            "version": "2.2.2",
            "identifier": "0be380429add00d189b4431059ac967a60052323",
            "dotted_decimal_identifier": "3346364756581632.58979677444790700.165452341125923",
            "cache_key": "jenkins-2.2.2-supermarket.chef.io",
            "origin": "https://supermarket.chef.io/api/v1/cookbooks/jenkins/versions/2.2.2/download",
            "source_options": {
              "artifactserver": "https://supermarket.chef.io/api/v1/cookbooks/jenkins/versions/2.2.2/download",
              "version": "2.2.2"
            }
          },
          "runit": {
            "version": "1.5.18",
            "identifier": "1a0aeb2c167a24e0c5120ca7b06ba8c4cff4610c",
            "dotted_decimal_identifier": "7330354567739940.63267076095586411.185563255955724",
            "cache_key": "runit-1.5.18-supermarket.chef.io",
            "origin": "https://supermarket.chef.io/api/v1/cookbooks/runit/versions/1.5.18/download",
            "source_options": {
              "artifactserver": "https://supermarket.chef.io/api/v1/cookbooks/runit/versions/1.5.18/download",
              "version": "1.5.18"
            }
          },
          "build-essential": {
            "version": "2.2.2",
            "identifier": "d8ce58401d154378599b0fead81d2c390615602b",
            "dotted_decimal_identifier": "61025473397593411.33875519727130653.48623426822187",
            "cache_key": "build-essential-2.2.2-supermarket.chef.io",
            "origin": "https://supermarket.chef.io/api/v1/cookbooks/build-essential/versions/2.2.2/download",
            "source_options": {
              "artifactserver": "https://supermarket.chef.io/api/v1/cookbooks/build-essential/versions/2.2.2/download",
              "version": "2.2.2"
            }
          },
          "yum": {
            "version": "3.5.4",
            "identifier": "f9c778c3cd3908071e0c55722682f96e653b5642",
            "dotted_decimal_identifier": "70306590695962888.2003363158959746.274252540106306",
            "cache_key": "yum-3.5.4-supermarket.chef.io",
            "origin": "https://supermarket.chef.io/api/v1/cookbooks/yum/versions/3.5.4/download",
            "source_options": {
              "artifactserver": "https://supermarket.chef.io/api/v1/cookbooks/yum/versions/3.5.4/download",
              "version": "3.5.4"
            }
          },
          "yum-epel": {
            "version": "0.6.0",
            "identifier": "cd74f541ba0341abcc168c74471c349ca68f77b7",
            "dotted_decimal_identifier": "57830966944203585.48356618235299612.57847413962679",
            "cache_key": "yum-epel-0.6.0-supermarket.chef.io",
            "origin": "https://supermarket.chef.io/api/v1/cookbooks/yum-epel/versions/0.6.0/download",
            "source_options": {
              "artifactserver": "https://supermarket.chef.io/api/v1/cookbooks/yum-epel/versions/0.6.0/download",
              "version": "0.6.0"
            }
          }
        },
        "default_attributes": {
          "greeting": "Attributes, f*** yeah"
        },
        "override_attributes": {
          "attr_only_updating": "use -a"
        },
        "solution_dependencies": {
          "Policyfile": [
            [
              "policyfile_demo",
              ">= 0.0.0"
            ],
            [
              "apt",
              "= 2.7.0"
            ],
            [
              "java",
              "= 1.31.0"
            ],
            [
              "jenkins",
              "= 2.2.2"
            ],
            [
              "runit",
              "= 1.5.18"
            ],
            [
              "build-essential",
              "= 2.2.2"
            ],
            [
              "yum",
              "= 3.5.4"
            ],
            [
              "yum-epel",
              "= 0.6.0"
            ]
          ],
          "dependencies": {
            "apt (2.7.0)": [

            ],
            "java (1.31.0)": [

            ],
            "jenkins (2.2.2)": [
              [
                "apt",
                "~> 2.0"
              ],
              [
                "runit",
                "~> 1.5"
              ],
              [
                "yum",
                "~> 3.0"
              ]
            ],
            "runit (1.5.18)": [
              [
                "build-essential",
                ">= 0.0.0"
              ],
              [
                "yum",
                "~> 3.0"
              ],
              [
                "yum-epel",
                ">= 0.0.0"
              ]
            ],
            "build-essential (2.2.2)": [

            ],
            "yum (3.5.4)": [

            ],
            "yum-epel (0.6.0)": [
              [
                "yum",
                "~> 3.0"
              ]
            ],
            "policyfile_demo (0.1.0)": [

            ]
          }
        }
      }
    E
  end

  let(:old_lock) { FFI_Yajl::Parser.parse(old_lock_json) }

  let(:new_lock) { old_lock }

  let(:new_rev_id) { "304566f86a620aae85797a3c491a51fb8c6ecf996407e77b8063aa3ee59672c5" }

  let(:ui) { TestHelpers::TestUI.new }

  def output
    # ANSI codes make the tests harder to read
    Paint.unpaint(ui.output)
  end

  subject(:differ) do
    described_class.new(old_name: "git: HEAD", old_lock: old_lock, new_name: "local disk", new_lock: new_lock, ui: ui)
  end

  it "has a UI object" do
    expect(differ.ui).to eq(ui)
  end

  it "has the old lock data" do
    expect(differ.old_lock).to eq(old_lock)
  end

  it "has the old lock `name'" do
    expect(differ.old_name).to eq("git: HEAD")
  end

  it "has the new lock data" do
    expect(differ.new_lock).to eq(new_lock)
  end

  it "has the new lock `name'" do
    expect(differ.new_name).to eq("local disk")
  end

  context "when old and new lock data are the same" do

    let(:new_lock) { old_lock }

    it "has no updates" do
      expect(differ.different?).to be(false)
    end

    it "has no updated sections" do
      expect(differ.updated_sections).to be_empty
    end

    it "reports that there are no updates" do
      expected_message = <<~E
        No changes for policy lock 'jenkins' between 'git: HEAD' and 'local disk'
      E
      differ.run_report
      expect(output).to include(expected_message)
    end

  end

  context "when the run list is updated" do

    let(:new_lock) do
      n = old_lock.dup
      n["revision_id"] = new_rev_id
      n["run_list"] = old_lock["run_list"].dup
      n["run_list"].delete_at(2)
      n["run_list"] += %w{ recipe[one::one] recipe[two::two] recipe[three::three]}
      n
    end

    it "has updates" do
      expect(differ.different?).to be(true)
    end

    it "has an updated revision_id and run_list" do
      expect(differ.updated_sections).to match_array(%w{revision_id run_list})
    end

    it "reports the updated rev_id and run_list" do
      expected_message = <<~E
        Policy lock 'jenkins' differs between 'git: HEAD' and 'local disk':

        REVISION ID CHANGED
        ===================

        @@ -1,2 +1,2 @@
        -cf4b8a020bdc1ba6914093a8a07a5514cce8a3a2979a967b1f32ea704a61785b
        +304566f86a620aae85797a3c491a51fb8c6ecf996407e77b8063aa3ee59672c5

        RUN LIST CHANGED
        ================

        @@ -1,5 +1,7 @@
         recipe[java::default]
         recipe[jenkins::master]
        -recipe[policyfile_demo::whatever]
         recipe[policyfile_demo::default]
        +recipe[one::one]
        +recipe[two::two]
        +recipe[three::three]

      E
      differ.run_report
      expect(output).to eq(expected_message)
    end

    # primary goal here is to make sure the differ behaves correctly when diff
    # "hunks" don't overlap
    context "when the run_list has non-contiguous changes" do

      let(:old_lock) do
        FFI_Yajl::Parser.parse(old_lock_json).tap do |l|
          l["run_list"] = %w{ a b c d e f g h i j k l m n }.map do |letter|
            "recipe[#{letter}::default]"
          end
        end
      end

      let(:new_lock) do
        old_lock.dup.tap do |n|
          n["revision_id"] = new_rev_id
          n["run_list"] = n["run_list"].dup
          n["run_list"].delete_at(1)
          n["run_list"] += %w{ o p q r }.map do |letter|
            "recipe[#{letter}::new]"
          end
        end
      end

      it "prints the correct changes with context for the run list" do
        expected_message = <<~E
          Policy lock 'jenkins' differs between 'git: HEAD' and 'local disk':

          REVISION ID CHANGED
          ===================

          @@ -1,2 +1,2 @@
          -cf4b8a020bdc1ba6914093a8a07a5514cce8a3a2979a967b1f32ea704a61785b
          +304566f86a620aae85797a3c491a51fb8c6ecf996407e77b8063aa3ee59672c5

          RUN LIST CHANGED
          ================

          @@ -1,5 +1,4 @@
           recipe[a::default]
          -recipe[b::default]
           recipe[c::default]
           recipe[d::default]
           recipe[e::default]
          @@ -12,4 +11,8 @@
           recipe[l::default]
           recipe[m::default]
           recipe[n::default]
          +recipe[o::new]
          +recipe[p::new]
          +recipe[q::new]
          +recipe[r::new]

        E
        differ.run_report
        expect(output).to eq(expected_message)
      end

    end
  end

  context "with a removed cookbook" do

    let(:new_lock) do
      old_lock.dup.tap do |n|
        n["revision_id"] = new_rev_id
        n["cookbook_locks"] = n["cookbook_locks"].dup
        n["cookbook_locks"].delete("apt")
      end
    end

    it "has updates" do
      expect(differ.different?).to be(true)
    end

    it "has an updated revision_id and cookbook_locks" do
      expect(differ.updated_sections).to match_array(%w{revision_id cookbook_locks})
    end

    it "has removed the 'apt' cookbook" do
      expect(differ.removed_cookbooks).to eq(%w{apt})
    end

    it "reports the updated revision_id and removed cookbooks" do
      expected_message = <<~E
        Policy lock 'jenkins' differs between 'git: HEAD' and 'local disk':

        REVISION ID CHANGED
        ===================

        @@ -1,2 +1,2 @@
        -cf4b8a020bdc1ba6914093a8a07a5514cce8a3a2979a967b1f32ea704a61785b
        +304566f86a620aae85797a3c491a51fb8c6ecf996407e77b8063aa3ee59672c5

        REMOVED COOKBOOKS
        =================

        apt
        ---

        @@ -1,12 +1 @@
        -{
        -  "version": "2.7.0",
        -  "identifier": "16c57abbd056543f7d5a15dabbb03261024a9c5e",
        -  "dotted_decimal_identifier": "6409580415309396.17870749399956400.55392231660638",
        -  "cache_key": "apt-2.7.0-supermarket.chef.io",
        -  "origin": "https://supermarket.chef.io/api/v1/cookbooks/apt/versions/2.7.0/download",
        -  "source_options": {
        -    "artifactserver": "https://supermarket.chef.io/api/v1/cookbooks/apt/versions/2.7.0/download",
        -    "version": "2.7.0"
        -  }
        -}

      E
      differ.run_report
      expect(output).to eq(expected_message)
    end

  end

  context "with an added cookbook" do

    let(:new_cookbook) do
      {
        "version" => "2.3.2",
        "identifier" => "9c6990944d9a347dec8bd375e707ba0aecdc17cd",
        "dotted_decimal_identifier" => "69437059924760478.24393100994078142.115593340606828",
        "cache_key" => "bluepill-2.3.2-supermarket.chef.io",
        "origin" => "https://supermarket.chef.io/api/v1/cookbooks/bluepill/versions/2.3.2/download",
        "source_options" => {
          "artifactserver" => "https://supermarket.chef.io/api/v1/cookbooks/bluepill/versions/2.3.2/download",
          "version" => "2.3.2",
        },
      }
    end

    let(:new_lock) do
      old_lock.dup.tap do |n|
        n["revision_id"] = new_rev_id
        n["cookbook_locks"] = n["cookbook_locks"].dup
        n["cookbook_locks"]["bluepill"] = new_cookbook
      end
    end

    it "has updates" do
      expect(differ.different?).to be(true)
    end

    it "has an updated revision_id and cookbook_locks" do
      expect(differ.updated_sections).to match_array(%w{revision_id cookbook_locks})
    end

    it "has added the bluepill cookbook" do
      expect(differ.added_cookbooks).to eq(%w{ bluepill })
    end

    it "reports the updated revision_id and added cookbook" do
      expected_message = <<~E
        Policy lock 'jenkins' differs between 'git: HEAD' and 'local disk':

        REVISION ID CHANGED
        ===================

        @@ -1,2 +1,2 @@
        -cf4b8a020bdc1ba6914093a8a07a5514cce8a3a2979a967b1f32ea704a61785b
        +304566f86a620aae85797a3c491a51fb8c6ecf996407e77b8063aa3ee59672c5

        ADDED COOKBOOKS
        ===============

        bluepill
        --------

        @@ -1 +1,12 @@
        +{
        +  "version": "2.3.2",
        +  "identifier": "9c6990944d9a347dec8bd375e707ba0aecdc17cd",
        +  "dotted_decimal_identifier": "69437059924760478.24393100994078142.115593340606828",
        +  "cache_key": "bluepill-2.3.2-supermarket.chef.io",
        +  "origin": "https://supermarket.chef.io/api/v1/cookbooks/bluepill/versions/2.3.2/download",
        +  "source_options": {
        +    "artifactserver": "https://supermarket.chef.io/api/v1/cookbooks/bluepill/versions/2.3.2/download",
        +    "version": "2.3.2"
        +  }
        +}

      E
      differ.run_report
      expect(output).to eq(expected_message)
    end

  end

  context "with a modified cookbook" do

    let(:new_lock) do
      old_lock.dup.tap do |n|
        n["revision_id"] = new_rev_id
        n["cookbook_locks"] = n["cookbook_locks"].dup
        policyfile_demo = n["cookbook_locks"]["policyfile_demo"].dup
        policyfile_demo["identifier"] = "f04cc40faf628253fe7d9566d66a1733fb1afbe9"
        policyfile_demo["dotted_decimal_identifier"] = "67638399371010690.23642238397896298.25512023620585"
        n["cookbook_locks"]["policyfile_demo"] = policyfile_demo
      end
    end

    it "has updates" do
      expect(differ.different?).to be(true)
    end

    it "has an updated revision_id and cookbook_locks" do
      expect(differ.updated_sections).to match_array(%w{revision_id cookbook_locks})
    end

    it "has modified the 'policyfile_demo' cookbook" do
      expect(differ.modified_cookbooks).to eq(%w{policyfile_demo})
    end

    it "reports the updated revision_id and modified policyfile_demo cookbook" do
      expected_message = <<~E
        Policy lock 'jenkins' differs between 'git: HEAD' and 'local disk':

        REVISION ID CHANGED
        ===================

        @@ -1,2 +1,2 @@
        -cf4b8a020bdc1ba6914093a8a07a5514cce8a3a2979a967b1f32ea704a61785b
        +304566f86a620aae85797a3c491a51fb8c6ecf996407e77b8063aa3ee59672c5

        MODIFIED COOKBOOKS
        ==================

        policyfile_demo
        ---------------

        @@ -1,7 +1,7 @@
         {
           "version": "0.1.0",
        -  "identifier": "ea96c99da079db9ff3cb22601638fabd5df49599",
        -  "dotted_decimal_identifier": "66030937227426267.45022575077627448.275691232073113",
        +  "identifier": "f04cc40faf628253fe7d9566d66a1733fb1afbe9",
        +  "dotted_decimal_identifier": "67638399371010690.23642238397896298.25512023620585",
           "source": "cookbooks/policyfile_demo",
           "cache_key": null,
           "scm_info": {

      E
      differ.run_report
      expect(output).to eq(expected_message)
    end

  end

  context "with updated default attributes" do

    let(:new_lock) do
      old_lock.dup.tap do |n|
        n["revision_id"] = new_rev_id
        n["default_attributes"] = n["default_attributes"].dup
        n["default_attributes"]["new_attr"] = "hello"
      end
    end

    it "has updates" do
      expect(differ.different?).to be(true)
    end

    it "has an updated revision_id and default_attributes" do
      expect(differ.updated_sections).to match_array(%w{revision_id default_attributes})
    end

    it "reports the updated revision_id and modified attributes" do
      expected_output = <<~E
        Policy lock 'jenkins' differs between 'git: HEAD' and 'local disk':

        REVISION ID CHANGED
        ===================

        @@ -1,2 +1,2 @@
        -cf4b8a020bdc1ba6914093a8a07a5514cce8a3a2979a967b1f32ea704a61785b
        +304566f86a620aae85797a3c491a51fb8c6ecf996407e77b8063aa3ee59672c5

        DEFAULT ATTRIBUTES CHANGED
        ==========================

        @@ -1,4 +1,5 @@
         {
        -  "greeting": "Attributes, f*** yeah"
        +  "greeting": "Attributes, f*** yeah",
        +  "new_attr": "hello"
         }

      E
      differ.run_report
      expect(output).to eq(expected_output)
    end

  end

  context "with updated override_attributes" do

    let(:new_lock) do
      old_lock.dup.tap do |n|
        n["revision_id"] = new_rev_id
        n["override_attributes"] = n["override_attributes"].dup
        n["override_attributes"]["new_attr"] = "ALL THE DIFF"
      end
    end

    it "has updates" do
      expect(differ.different?).to be(true)
    end

    it "has an updated revision_id and override_attributes" do
      expect(differ.updated_sections).to match_array(%w{revision_id override_attributes})
    end

    it "reports the updated revision_id and override_attributes" do
      expected_output = <<~E
        Policy lock 'jenkins' differs between 'git: HEAD' and 'local disk':

        REVISION ID CHANGED
        ===================

        @@ -1,2 +1,2 @@
        -cf4b8a020bdc1ba6914093a8a07a5514cce8a3a2979a967b1f32ea704a61785b
        +304566f86a620aae85797a3c491a51fb8c6ecf996407e77b8063aa3ee59672c5

        OVERRIDE ATTRIBUTES CHANGED
        ===========================

        @@ -1,4 +1,5 @@
         {
        -  "attr_only_updating": "use -a"
        +  "attr_only_updating": "use -a",
        +  "new_attr": "ALL THE DIFF"
         }

      E

      differ.run_report
      expect(output).to eq(expected_output)
    end
  end

end
