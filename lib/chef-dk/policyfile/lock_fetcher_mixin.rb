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

require_relative "../exceptions"

module ChefDK
  module Policyfile
    module LockFetcherMixin
      def validate_revision_id(included_id, source_options)
        expected_id = source_options[:policy_revision_id]
        if expected_id
          if included_id.eql?(expected_id) # are they the same?
            return
          elsif included_id[0, 10].eql?(expected_id) # did they use the 10 char substring
            return
          else
            raise ChefDK::InvalidLockfile, "Expected policy_revision_id '#{expected_id}' does not match included_policy '#{included_id}'."
          end
        end
      end
    end
  end
end
