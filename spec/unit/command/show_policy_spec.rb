#
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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

require 'spec_helper'
require 'shared/command_with_ui_object'
require 'chef-dk/command/show_policy'

describe ChefDK::Command::ShowPolicy do

  it_behaves_like "a command with a UI object"

  let(:command) do
    described_class.new
  end

  let(:chef_config_loader) { instance_double("Chef::WorkstationConfigLoader") }

  let(:chef_config) { double("Chef::Config") }

  # nil means the config loader will do the default path lookup
  let(:config_arg) { nil }

  before do
    stub_const("Chef::Config", chef_config)
    allow(Chef::WorkstationConfigLoader).to receive(:new).with(config_arg).and_return(chef_config_loader)
  end

  describe "parsing args and options" do
    let(:params) { [] }

    before do
      command.apply_params!(params)
    end

    context "with no params" do

      it "disables debug by default" do
        expect(command.debug?).to be(false)
      end

      it "is configured to show all policies across all groups" do
        expect(command.show_all_policies?).to be(true)
      end

      it "disables displaying orphans" do
        expect(command.show_orphans?).to be(false)
      end

    end

    context "when debug mode is set" do

      let(:params) { [ "-D" ] }

      it "enables debug" do
        expect(command.debug?).to be(true)
      end

    end

    context "when --show-orphans is given" do

      let(:params) { %w[ -o ] }

      it "enables displaying orphans" do
        expect(command.show_orphans?).to be(true)
      end

    end

    context "when given a path to the config" do

      let(:params) { %w[ -c ~/otherstuff/config.rb ] }

      let(:config_arg) { "~/otherstuff/config.rb" }

      before do
        expect(chef_config_loader).to receive(:load)
      end

      it "reads the chef/knife config" do
        expect(Chef::WorkstationConfigLoader).to receive(:new).with(config_arg).and_return(chef_config_loader)
        expect(command.chef_config).to eq(chef_config)
      end

    end

    context "when given a policy name" do

      let(:params) { %w[ appserver ] }

      it "is not configured to show all policies" do
        expect(command.show_all_policies?).to be(false)
      end

      it "is configured to show the given policy" do
        expect(command.policy_name).to eq("appserver")
      end

      context "and the summary diff option `-s`" do

        let(:params) { %w[ appserver -s ] }

        it "enables summary diff output" do
          expect(command.show_summary_diff?).to be(true)
        end

      end

    end

  end

  describe "running the command" do

    let(:ui) { TestHelpers::TestUI.new }

    let(:policy_info) { command.policy_info_fetcher }

    before do
      command.ui = ui
    end

    context "when given too many arguments" do

      let(:params) { %w[ appserver chatserver ] }

      it "shows usage and exits" do
        expect(command.run(params)).to eq(1)
      end

    end

    context "when the summary diff option is given but no policy name is specified" do

      let(:params) { %w[ -s ] }

      it "prints a message explaining that -s only applies to single policy" do
        expect(command.run(params)).to eq(1)
      end

    end


    describe "show all" do

      let(:params) { [] }

      let(:policies_by_name) { {} }
      let(:policies_by_group) { {} }

      before do
        policy_info.set!(policies_by_name, policies_by_group)
      end

      context "when an error occurs contacting the server" do

        it "displays the error and exits"

      end

      context "when there are no policies or groups on the server" do

        it "prints a message to stderr that there aren't any policies or groups" do
          expect(command.run(params)).to eq(0)
          expect(ui.output).to eq("No policies or policy groups exist on the server\n")
        end

      end

      context "when there are policies but no groups" do

        let(:policies_by_name) do
          {
            "appserver" => {
              "1111111111111111111111111111111111111111111111111111111111111111" => {},
              "2222222222222222222222222222222222222222222222222222222222222222" => {}
            },
            "load-balancer" => {
              "5555555555555555555555555555555555555555555555555555555555555555" => {},
              "6666666666666666666666666666666666666666666666666666666666666666" => {},
            },
            "db" => {
              "9999999999999999999999999999999999999999999999999999999999999999" => {},
              "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" => {}
            }
          }
        end

        it "prints a message to stderr that there are no active policies" do
          expect(command.run(params)).to eq(0)
          expected_output = <<-OUTPUT
appserver
=========

Policy appserver is not assigned to any groups

load-balancer
=============

Policy load-balancer is not assigned to any groups

db
==

Policy db is not assigned to any groups

OUTPUT
          expect(ui.output).to eq(expected_output)
        end

        context "with orphans shown" do

          let(:params) { %w[ -o ] }

          it "shows all policies as orphaned" do
            expect(command.run(params)).to eq(0)
            expected_output = <<-OUTPUT
appserver
=========

Policy appserver is not assigned to any groups

Orphaned:
---------

* 1111111111
* 2222222222

load-balancer
=============

Policy load-balancer is not assigned to any groups

Orphaned:
---------

* 5555555555
* 6666666666

db
==

Policy db is not assigned to any groups

Orphaned:
---------

* 9999999999
* aaaaaaaaaa

OUTPUT
            expect(ui.output).to eq(expected_output)
          end
        end

      end

      context "when there are groups but no policies" do

        let(:policies_by_group) do
          {
            "dev" => {},
            "staging" => {},
            "prod" => {}
          }
        end

        it "prints a message to stderr and exits" do
          expect(command.run(params)).to eq(0)
          expect(ui.output).to eq("No policies exist on the server\n")
        end

      end

      context "when there is a revision of each kind of policy assigned to every policy group" do

        let(:policies_by_name) do
          {
            "appserver" => {
              "1111111111111111111111111111111111111111111111111111111111111111" => {},
              "2222222222222222222222222222222222222222222222222222222222222222" => {}
            },
            "load-balancer" => {
              "5555555555555555555555555555555555555555555555555555555555555555" => {},
              "6666666666666666666666666666666666666666666666666666666666666666" => {},
            },
            "db" => {
              "9999999999999999999999999999999999999999999999999999999999999999" => {},
              "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" => {}
            }
          }
        end

        let(:policies_by_group) do
          {
            "dev" => {
              "appserver" => "1111111111111111111111111111111111111111111111111111111111111111",
              "load-balancer" => "5555555555555555555555555555555555555555555555555555555555555555",
              "db" => "9999999999999999999999999999999999999999999999999999999999999999"
            },
            "staging" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222",
              "load-balancer" => "5555555555555555555555555555555555555555555555555555555555555555",
              "db" => "9999999999999999999999999999999999999999999999999999999999999999"
            },
            "prod" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222",
              "load-balancer" => "6666666666666666666666666666666666666666666666666666666666666666",
              "db" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            }
          }
        end

        it "shows each policy name, followed by a list of group_name -> revision" do
          expected_output = <<-OUTPUT
appserver
=========

* dev:      1111111111
* staging:  2222222222
* prod:     2222222222

load-balancer
=============

* dev:      5555555555
* staging:  5555555555
* prod:     6666666666

db
==

* dev:      9999999999
* staging:  9999999999
* prod:     aaaaaaaaaa

OUTPUT
          expect(command.run(params)).to eq(0)
          expect(ui.output).to eq(expected_output)
        end

      end

      context "when there is a revision of each kind of policy assigned to every policy group, plus orphaned policies" do
        let(:policies_by_name) do
          {
            "appserver" => {
              "1111111111111111111111111111111111111111111111111111111111111111" => {},
              "2222222222222222222222222222222222222222222222222222222222222222" => {},
              "3333333333333333333333333333333333333333333333333333333333333333" => {}
            },
            "load-balancer" => {
              "5555555555555555555555555555555555555555555555555555555555555555" => {},
              "6666666666666666666666666666666666666666666666666666666666666666" => {},
              "7777777777777777777777777777777777777777777777777777777777777777" => {}
            },
            "db" => {
              "9999999999999999999999999999999999999999999999999999999999999999" => {},
              "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" => {},
              "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb" => {}
            }
          }
        end

        let(:policies_by_group) do
          {
            "dev" => {
              "appserver" => "1111111111111111111111111111111111111111111111111111111111111111",
              "load-balancer" => "5555555555555555555555555555555555555555555555555555555555555555",
              "db" => "9999999999999999999999999999999999999999999999999999999999999999"
            },
            "staging" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222",
              "load-balancer" => "5555555555555555555555555555555555555555555555555555555555555555",
              "db" => "9999999999999999999999999999999999999999999999999999999999999999"
            },
            "prod" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222",
              "load-balancer" => "6666666666666666666666666666666666666666666666666666666666666666",
              "db" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            }
          }
        end

        it "shows each policy name, followed by a list of group_name -> revision, followed by a list of orphaned policies" do
          expected_output = <<-OUTPUT
appserver
=========

* dev:      1111111111
* staging:  2222222222
* prod:     2222222222

load-balancer
=============

* dev:      5555555555
* staging:  5555555555
* prod:     6666666666

db
==

* dev:      9999999999
* staging:  9999999999
* prod:     aaaaaaaaaa

OUTPUT
          expect(command.run(params)).to eq(0)
          expect(ui.output).to eq(expected_output)
        end

        context "with orphans shown" do

          let(:params) { %w[ -o ] }

          it "shows each policy name, followed by a list of group_name -> revision, followed by a list of orphaned policies" do
            expected_output = <<-OUTPUT
appserver
=========

* dev:      1111111111
* staging:  2222222222
* prod:     2222222222

Orphaned:
---------

* 3333333333

load-balancer
=============

* dev:      5555555555
* staging:  5555555555
* prod:     6666666666

Orphaned:
---------

* 7777777777

db
==

* dev:      9999999999
* staging:  9999999999
* prod:     aaaaaaaaaa

Orphaned:
---------

* bbbbbbbbbb

OUTPUT
            expect(command.run(params)).to eq(0)
            expect(ui.output).to eq(expected_output)
          end

        end
      end

      context "when some groups do not have a revision of every policy" do
        let(:policies_by_name) do
          {
            "appserver" => {
              "1111111111111111111111111111111111111111111111111111111111111111" => {},
              "2222222222222222222222222222222222222222222222222222222222222222" => {}
            },
            "load-balancer" => {
              "5555555555555555555555555555555555555555555555555555555555555555" => {},
              "6666666666666666666666666666666666666666666666666666666666666666" => {},
            },
            "db" => {
              "9999999999999999999999999999999999999999999999999999999999999999" => {},
              "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa" => {}
            },
            "memcache" => {
              "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd" => {}
            }
          }
        end

        let(:policies_by_group) do
          {
            "dev" => {
              "appserver" => "1111111111111111111111111111111111111111111111111111111111111111",
              "load-balancer" => "5555555555555555555555555555555555555555555555555555555555555555",
              "db" => "9999999999999999999999999999999999999999999999999999999999999999",
              "memcache" => "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
            },
            "staging" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222",
              "load-balancer" => "5555555555555555555555555555555555555555555555555555555555555555",
              "db" => "9999999999999999999999999999999999999999999999999999999999999999",
              "memcache" => "dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"
            },
            "prod" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222",
              "load-balancer" => "6666666666666666666666666666666666666666666666666666666666666666",
              "db" => "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            }
          }
        end


        it "shows each policy name, followed by a list of group_name -> revision, omitting groups that don't have that policy" do
          expected_output = <<-OUTPUT
appserver
=========

* dev:      1111111111
* staging:  2222222222
* prod:     2222222222

load-balancer
=============

* dev:      5555555555
* staging:  5555555555
* prod:     6666666666

db
==

* dev:      9999999999
* staging:  9999999999
* prod:     aaaaaaaaaa

memcache
========

* dev:      dddddddddd
* staging:  dddddddddd
* prod:     *NOT APPLIED*

OUTPUT
          expect(command.run(params)).to eq(0)
          expect(ui.output).to eq(expected_output)
        end

      end
    end

    describe "showing a single policy" do

      let(:params) { %w[ appserver ] }

      let(:policies_by_name) { {} }
      let(:policies_by_group) { {} }

      before do
        policy_info.set!(policies_by_name, policies_by_group)
      end

      context "when an error occurs contacting the server" do

        it "displays the error and exits"

      end

      context "when there are no revisions of the policy on the server" do

        let(:policies_by_name) do
          {}
        end

        let(:policies_by_group) do
          {}
        end

        it "prints a message to stderr that there are no copies of the policy on the server" do
          expected_output = <<-OUTPUT
appserver
=========

No policies named 'appserver' are associated with a policy group

OUTPUT

          expect(command.run(params)).to eq(0)
          expect(ui.output).to eq(expected_output)
        end

      end

      context "when all policies are orphaned and orphans are not shown" do
        let(:policies_by_name) do
          {
            "appserver" => {
              "1111111111111111111111111111111111111111111111111111111111111111" => {},
              "2222222222222222222222222222222222222222222222222222222222222222" => {},
              "3333333333333333333333333333333333333333333333333333333333333333" => {}
            }
          }

        end

        let(:policies_by_group) do
          {}
        end

        it "explains that no policies are assigned to a group" do
          expected_output = <<-OUTPUT
appserver
=========

No policies named 'appserver' are associated with a policy group

OUTPUT

          expect(command.run(params)).to eq(0)
          expect(ui.output).to eq(expected_output)
        end
      end

      context "when all policy groups have the same revision of the policy" do

        let(:policies_by_name) do
          {
            "appserver" => {
              "1111111111111111111111111111111111111111111111111111111111111111" => {},
              "2222222222222222222222222222222222222222222222222222222222222222" => {},
              "3333333333333333333333333333333333333333333333333333333333333333" => {}
            }
          }

        end

        let(:policies_by_group) do
          {
            "dev" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222"
            },
            "staging" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222"
            },
            "prod" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222"
            }
          }
        end
        it "lists each of the groups with the associated revision" do
          expected_output = <<-OUTPUT
appserver
=========

* dev:      2222222222
* staging:  2222222222
* prod:     2222222222

OUTPUT
          expect(command.run(params)).to eq(0)
          expect(ui.output).to eq(expected_output)
        end

      end

      context "when policy groups have revisions with differing cookbooks" do

        let(:policies_by_name) do
          {
            "appserver" => {
              "1111111111111111111111111111111111111111111111111111111111111111" => {},
              "2222222222222222222222222222222222222222222222222222222222222222" => {},
              "3333333333333333333333333333333333333333333333333333333333333333" => {}
            }
          }

        end

        let(:policies_by_group) do
          {
            "dev" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222"
            },
            "staging" => {
              "appserver" => "2222222222222222222222222222222222222222222222222222222222222222"
            },
            "prod" => {
              "appserver" => "1111111111111111111111111111111111111111111111111111111111111111"
            }
          }
        end

        it "lists each of the groups with the associated revision" do
          expected_output = <<-OUTPUT
appserver
=========

* dev:      2222222222
* staging:  2222222222
* prod:     1111111111

OUTPUT
          expect(command.run(params)).to eq(0)
          expect(ui.output).to eq(expected_output)
        end

        context "when the diff summary option is given" do

          let(:appserver_lock_contents_111) do
            {
              "cookbook_locks" => {
                "apache2" => {
                  "version" => "2.1.3",
                  "identifier" => "abcdef" + ("0" * 34)
                },
                "yum" => {
                  "version" => "4.5.6",
                  "identifier" => "123abc" + ("0" * 34)
                },
                "apt" => {
                  "version" => "10.0.0",
                  "identifier" => "ffffff" + ("0" * 34)
                }

              }
            }
          end

          let(:appserver_lock_contents_222) do
            {
              "cookbook_locks" => {
                "apache2" => {
                  "version" => "2.0.5",
                  "identifier" => "aaa123" + ("0" * 34)
                },
                "yum" => {
                  "version" => "4.5.2",
                  "identifier" => "867530" + ("9" * 34)
                },
                "apt" => {
                  "version" => "10.0.0",
                  "identifier" => "ffffff" + ("0" * 34)
                },
                "other_cookbook" => {
                  "version" => "9.8.7",
                  "identifier" => "113113" + ("0" * 34)
                }
              }
            }
          end

          let(:appserver_lock_content) do
            {
              "appserver" => {
                "1111111111111111111111111111111111111111111111111111111111111111" => appserver_lock_contents_111,
                "2222222222222222222222222222222222222222222222222222222222222222" => appserver_lock_contents_222,
              }
            }
          end

          let(:params) { %w[ appserver -s ] }

          before do
            policy_info.policy_lock_content = appserver_lock_content
          end

          it "lists each of the groups and displays the version and identifier of the differing cookbooks" do
            expected_output = <<-OUTPUT
appserver
=========

dev:     2222222222
-------------------

* apache2:         2.0.5 (aaa1230000)
* yum:             4.5.2 (8675309999)
* other_cookbook:  9.8.7 (1131130000)

staging: 2222222222
-------------------

* apache2:         2.0.5 (aaa1230000)
* yum:             4.5.2 (8675309999)
* other_cookbook:  9.8.7 (1131130000)

prod:    1111111111
-------------------

* apache2:         2.1.3 (abcdef0000)
* yum:             4.5.6 (123abc0000)
* other_cookbook:  *NONE*

OUTPUT
            expect(command.run(params)).to eq(0)
            expect(ui.output).to eq(expected_output)
          end
        end

        context "when orphans are displayed" do

          let(:params) { %w[ appserver -o ] }

          it "lists each of the groups, then lists the orphaned revisions" do
            expected_output = <<-OUTPUT
appserver
=========

* dev:      2222222222
* staging:  2222222222
* prod:     1111111111

Orphaned:
---------

* 3333333333

OUTPUT

            expect(command.run(params)).to eq(0)
            expect(ui.output).to eq(expected_output)
          end

        end
      end



    end
  end
end

