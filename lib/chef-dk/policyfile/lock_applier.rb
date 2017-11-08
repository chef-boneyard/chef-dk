module ChefDK
  module Policyfile

    # A class that can apply constraints from a lock to a compiler
    class LockApplier
      attr_reader :unlocked_policies
      attr_reader :policyfile_lock
      attr_reader :policyfile_compiler

      def initialize(policyfile_lock, policyfile_compiler)
        @policyfile_lock = policyfile_lock
        @policyfile_compiler = policyfile_compiler
        @unlocked_policies = []
      end

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

      # No changes are applied until apply! is invoked
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
