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

module ChefDK
  module Policyfile
    module Reports

      # Defines a table with a flexible number of columns and prints rows in
      # the table. Columns are defined ahead of time, by calling the #column
      # method, individual rows are printed by calling #print_row with the data
      # for each cell.
      class TablePrinter

        attr_reader :ui

        def initialize(ui)
          @ui = ui
          @column_widths = []

          yield self
        end

        # Defines a column. If a collection is given, it is mapped to an array
        # of strings and the longest string is used as the left justify width
        # for that column when rows are printed.
        def column(collection = [])
          @column_widths << (collection.map(&:to_s).map(&:size).max || 0)
        end

        # Print a row.
        def print_row(*cells)
          row = ""
          cells.each_with_index do |cell_data, i|
            row << cell_data.to_s.ljust(@column_widths[i])
            row << " "
          end
          ui.msg(row.strip)
        end

      end
    end
  end
end
