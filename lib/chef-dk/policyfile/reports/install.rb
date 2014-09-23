#
# Copyright:: Copyright (c) 2014 Chef Software Inc.
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


module ChefDK
  module Policyfile
    module Reports

      class Install

        attr_reader :ui
        attr_reader :policyfile_compiler

        def initialize(ui: nil, policyfile_compiler: nil)
          @ui = ui
          @policyfile_compiler = policyfile_compiler

          @fixed_version_cookbooks_name_width = nil
          @cookbook_name_width = nil
          @cookbook_version_width = nil
        end

        def installing_fixed_version_cookbook(cookbook_spec)
          verb = cookbook_spec.installed? ? "Using     " : "Installing"
          ui.msg("#{verb} #{format_fixed_version_cookbook(cookbook_spec)}")
        end

        def installing_cookbook(cookbook_spec)
          verb = cookbook_spec.installed? ? "Using     " : "Installing"
          ui.msg("#{verb} #{format_cookbook(cookbook_spec)}")
        end

        private

        def format_cookbook(cookbook_spec)
          "#{cookbook_spec.name.ljust(cookbook_name_width)} #{cookbook_spec.version_constraint.version.to_s.ljust(cookbook_version_width)}"
        end

        def cookbook_name_width
          @cookbook_name_width ||= policyfile_compiler.graph_solution.map { |name, _| name.size }.max
        end

        def cookbook_version_width
          @cookbook_version_width ||= policyfile_compiler.graph_solution.map { |_, version| version.size }.max
        end

        def format_fixed_version_cookbook(spec)
          "#{spec.name.ljust(fixed_version_cookbooks_name_width)} #{spec.version_constraint} from #{spec.source_type}"
        end

        def fixed_version_cookbooks_name_width
          @fixed_version_cookbooks_name_width ||= policyfile_compiler.fixed_version_cookbooks_specs.map { |name, _| name.size }.max
        end

      end
    end
  end
end

