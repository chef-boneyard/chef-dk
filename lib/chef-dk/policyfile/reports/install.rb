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

require "chef-dk/policyfile/reports/table_printer"

module ChefDK
  module Policyfile
    module Reports

      class Install

        attr_reader :ui
        attr_reader :policyfile_compiler

        def initialize(ui: nil, policyfile_compiler: nil)
          @ui = ui
          @policyfile_compiler = policyfile_compiler

          @fixed_version_install_table = nil
          @install_table = nil
        end

        def installing_fixed_version_cookbook(cookbook_spec)
          verb = cookbook_spec.installed? ? "Using     " : "Installing"
          fixed_version_install_table.print_row(verb, cookbook_spec.name, cookbook_spec.version_constraint.to_s, "from #{cookbook_spec.source_type}")
        end

        def installing_cookbook(cookbook_spec)
          verb = cookbook_spec.installed? ? "Using     " : "Installing"
          install_table.print_row(verb, cookbook_spec.name, cookbook_spec.version_constraint.version)
        end

        private

        def fixed_version_install_table
          @fixed_version_install_table ||= TablePrinter.new(ui) do |t|
            t.column(%w{Using Installing})
            t.column(policyfile_compiler.fixed_version_cookbooks_specs.keys)
            t.column
            t.column
          end
        end

        def install_table
          @install_table ||= TablePrinter.new(ui) do |t|
            t.column(%w{Using Installing})
            t.column(policyfile_compiler.graph_solution.keys)
            t.column(policyfile_compiler.graph_solution.values)
          end
        end

      end
    end
  end
end
