#
# Copyright:: Copyright (c) 2017 Chef Software Inc.
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

    # A class that can apply constraints from a lock to a compiler
    class LockApplier
      attr_reader :unlocked_policies
      attr_reader :policyfile_lock
      attr_reader :policyfile_compiler

      # Initialize a LockApplier. By default, all locked data this class knows
      # about will be applied to the compiler. Currently, it applies locks only
      # for included policies.
      #
      # @param policyfile_lock [PolicyfileLock] contains the locked data to use
      # @param policyfile_compiler [PolicyfileCompiler] the compiler to apply the locked data
      def initialize(policyfile_lock, policyfile_compiler)
        @policyfile_lock = policyfile_lock
        @policyfile_compiler = policyfile_compiler
        @unlocked_policies = []
      end

      # Unlocks included policies
      #
      # @param policies [:all] Unconstrain all policies
      # @param policies [Array<String>] Unconstrain a specific policy by name
      def with_unlocked_policies(policies)
        if policies == :all || unlocked_policies == :all
          @unlocked_policies = :all
        else
          policies.each do |policy|
            @unlocked_policies << policy
          end
        end
        self
      end

      # Apply locks described in policyfile_lock allowing for the deviations asked
      # for.
      #
      # @note No changes are applied until apply! is invoked
      def apply!
        prepare_constraints_for_policies
      end

      private

      def prepare_constraints_for_policies
        if unlocked_policies == :all
          return
        end

        policyfile_compiler.included_policies.each do |policy|
          if !unlocked_policies.include?(policy.name)
            lock = policyfile_lock.included_policy_locks.find do |policy_lock|
              policy_lock["name"] == policy.name
            end
            policy.apply_locked_source_options(lock["source_options"])
          end
        end
      end
    end
  end
end
