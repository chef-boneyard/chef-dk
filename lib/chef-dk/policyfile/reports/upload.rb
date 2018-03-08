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
      class Upload

        attr_reader :reused_cbs
        attr_reader :uploaded_cbs
        attr_reader :ui

        def initialize(reused_cbs: [], uploaded_cbs: [], ui: nil)
          @reused_cbs = reused_cbs
          @uploaded_cbs = uploaded_cbs
          @ui = ui

          @justify_name_width = nil
          @justify_version_width = nil
        end

        def show
          reused_cbs.each do |cb_with_lock|
            lock = cb_with_lock.lock
            table.print_row("Using", lock.name, lock.version, "(#{lock.identifier[0, 8]})")
          end

          uploaded_cbs.each do |cb_with_lock|
            lock = cb_with_lock.lock
            table.print_row("Uploaded", lock.name, lock.version, "(#{lock.identifier[0, 8]})")
          end
        end

        def table
          @table ||= TablePrinter.new(ui) do |t|
            t.column(%w{ Using Uploaded })
            t.column(cookbook_names)
            t.column(cookbook_version_numbers)
            t.column
          end
        end

        def cookbook_names
          (reused_cbs + uploaded_cbs).map { |e| e.lock.name }
        end

        def cookbook_version_numbers
          (reused_cbs + uploaded_cbs).map { |e| e.lock.version }
        end

      end
    end
  end
end
