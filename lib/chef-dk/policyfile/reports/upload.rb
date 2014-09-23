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
            ui.msg("Using    #{describe_lock(cb_with_lock.lock, justify_name_width, justify_version_width)}")
          end

          uploaded_cbs.each do |cb_with_lock|
            ui.msg("Uploaded #{describe_lock(cb_with_lock.lock, justify_name_width, justify_version_width)}")
          end
        end

        def justify_name_width
          @justify_name_width ||= cookbook_names.map {|e| e.size }.max
        end

        def justify_version_width
          @justify_version_width ||= cookbook_version_numbers.map {|e| e.size }.max
        end

        def cookbook_names
          (reused_cbs + uploaded_cbs).map { |e| e.lock.name }
        end

        def cookbook_version_numbers
          (reused_cbs + uploaded_cbs).map { |e| e.lock.version }
        end

        def describe_lock(lock, justify_name_width, justify_version_width)
          "#{lock.name.ljust(justify_name_width)} #{lock.version.ljust(justify_version_width)} (#{lock.identifier[0,8]})"
        end

      end
    end
  end
end
