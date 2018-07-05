#
# Copyright:: Copyright (c) 2016 Chef Software Inc.
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

ChefDK.commands do |c|
  c.builtin "exec", :Exec, require_path: "chef-dk/command/exec",
                           desc: "Runs the command in context of the embedded ruby"

  c.builtin "env", :Env, require_path: "chef-dk/command/env",
                         desc: "Prints environment variables used by ChefDK"

  c.builtin "gem", :GemForwarder, require_path: "chef-dk/command/gem",
                                  desc: "Runs the `gem` command in context of the embedded ruby"

  c.builtin "generate", :Generate, desc: "Generate a new app, cookbook, or component"

  c.builtin "shell-init", :ShellInit, desc: "Initialize your shell to use ChefDK as your primary ruby"

  c.builtin "install", :Install, desc: "Install cookbooks from a Policyfile and generate a locked cookbook set"

  c.builtin "update", :Update, desc: "Updates a Policyfile.lock.json with latest run_list and cookbooks"

  c.builtin "push", :Push, desc: "Push a local policy lock to a policy group on the server"

  c.builtin "push-archive", :PushArchive, desc: "Push a policy archive to a policy group on the server"

  c.builtin "show-policy", :ShowPolicy, desc: "Show policyfile objects on your Chef Server"

  c.builtin "diff", :Diff, desc: "Generate an itemized diff of two Policyfile lock documents"

  c.builtin "export", :Export, desc: "Export a policy lock as a Chef Zero code repo"

  c.builtin "clean-policy-revisions", :CleanPolicyRevisions, desc: "Delete unused policy revisions on the server"

  c.builtin "clean-policy-cookbooks", :CleanPolicyCookbooks, desc: "Delete unused policyfile cookbooks on the server"

  c.builtin "delete-policy-group", :DeletePolicyGroup, desc: "Delete a policy group on the server"

  c.builtin "delete-policy", :DeletePolicy, desc: "Delete all revisions of a policy on the server"

  c.builtin "undelete", :Undelete, desc: "Undo a delete command"

  c.builtin "describe-cookbook", :DescribeCookbook, require_path: "chef-dk/command/describe_cookbook",
                                                    desc: "Prints cookbook checksum information used for cookbook identifier"

  c.builtin "verify", :Verify, desc: "Test the embedded ChefDK applications", hidden: true
end
