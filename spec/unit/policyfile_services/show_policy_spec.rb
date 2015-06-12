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
require 'chef-dk/policyfile_services/show_policy'

describe ChefDK::PolicyfileServices::ShowPolicy do

  let(:chef_config) { double("Chef::Config") }

  let(:show_all) { true }

  let(:ui) { TestHelpers::TestUI.new }

  let(:policy_name) { nil }

  let(:show_orphans) { false }

  let(:summary_diff) { false }

  subject(:show_policy_service) do
    described_class.new(config: chef_config,
                        show_all: show_all,
                        ui: ui,
                        policy_name: policy_name,
                        show_orphans: show_orphans,
                        summary_diff: summary_diff)
  end

  let(:policy_lister) do
    show_policy_service.policy_lister
  end

  describe "show all" do

    let(:params) { [] }

    let(:policies_by_name) { {} }
    let(:policies_by_group) { {} }

    let(:policyfile_locks_content) {}

    describe "when an error occurs fetching data from the server" do

      let(:http_client) { instance_double(ChefDK::AuthenticatedHTTP) }

      # TODO: make this reusable
      let(:response) do
        Net::HTTPResponse.send(:response_class, "500").new("1.0", "500", "Internal Server Error").tap do |r|
          r.instance_variable_set(:@body, "oops")
        end
      end

      let(:http_exception) do
        begin
          response.error!
        rescue => e
          e
        end
      end

      let(:policies_url) { "/policies" }

      let(:policy_groups_url) { "/policy_groups" }

      before do
        allow(policy_lister).to receive(:http_client).and_return(http_client)
      end

      describe "when fetching policy revisions by policy group" do

        before do
          expect(http_client).to receive(:get).and_raise(http_exception)
        end

        it "raises an error" do
          expect { show_policy_service.run }.to raise_error(ChefDK::PolicyfileListError)
        end
      end

    end

    context "when the server returns the data successfully" do

      before do
        policy_lister.set!(policies_by_name, policies_by_group)
        policy_lister.policy_lock_content = policyfile_locks_content

        show_policy_service.run
      end

      context "when there are no policies or groups on the server" do

        it "prints a message to stderr that there aren't any policies or groups" do
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

          let(:show_orphans) { true }

          it "shows all policies as orphaned" do
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
          expect(ui.output).to eq(expected_output)
        end

        context "with orphans shown" do

          let(:show_orphans) { true }

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
          expect(ui.output).to eq(expected_output)
        end

      end
    end

    describe "showing a single policy" do

      let(:policy_name) { "appserver" }

      let(:show_all) { false }

      let(:policies_by_name) { {} }
      let(:policies_by_group) { {} }

      before do
        policy_lister.set!(policies_by_name, policies_by_group)
      end

      context "when the server returns the data successfully" do

        before do
          policy_lister.set!(policies_by_name, policies_by_group)
          policy_lister.policy_lock_content = policyfile_locks_content

          show_policy_service.run
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

            let(:policyfile_locks_content) do
              {
                "appserver" => {
                  "1111111111111111111111111111111111111111111111111111111111111111" => appserver_lock_contents_111,
                  "2222222222222222222222222222222222222222222222222222222222222222" => appserver_lock_contents_222,
                }
              }
            end

            let(:summary_diff) { true }

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
              expect(ui.output).to eq(expected_output)
            end
          end

          context "when orphans are displayed" do

            let(:show_orphans) { true }

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

              expect(ui.output).to eq(expected_output)
            end

          end
        end

      end
    end
  end
end

