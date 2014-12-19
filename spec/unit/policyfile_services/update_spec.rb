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

require 'spec_helper'

# TODO: change this from string to const when class definition exists
describe "ChefDK::PolicyfileServices::Update" do

  context "when given one cookbook to update" do

    context "and there is not a newer version available" do

      it "does not update the cookbook"

      it "explains that no newer version is available"

    end

    context "and a newer version is available" do

      context "and the cookbook has no deps and is not a dep of another cookbook" do

        it "updates the cookbook"

      end

      context "and there is a version contraint in the policyfile that is satisfied by the new version" do

        it "updates the cookbook"

      end

      context "and there is a version contraint in the policyfile that is not satisfied by the new version" do

        it "does not update the cookbook"

        it "explains why dependency conflicts prevented the update"

      end

      context "and the cookbook has deps that are not shared with other cookbooks" do

        it "updates the cookbook"

        context "and the cookbook's deps have a newer version available" do

          it "updates the cookbook's dependency"

        end

        context "and the updated cookbook removed a dependency" do

          it "removes the dependent cookbook"

        end

      end

      context "and the cookbook has deps that are shared with other cookbooks" do

        context "and the updated dep satisfies the other cookbook's constraints" do

          it "updates the cookbook"

          it "updates the dependency"

        end

        context "and the updated dep doesn't satisfy the other cookbook's contstraints" do

          context "and the updated cookbook requires the updated dependency" do

            it "does not update the cookbook"

            it "explains why dependency conflicts prevented the update"

          end

          context "and the updated cookbook does not require the updated dependency" do

            it "updates the cookbook"

            it "does not update the dependency"

          end

        end

        context "and the updated cookbook removes the dependency" do

          it "updates the cookbook"

          # NOTE: the ideal behavior here is probably not updating the
          # dependency, because we update dependencies only to make the update
          # of the depending cookbook less likely to fail, which is irrelevant
          # in this scenario. That said, it is expected that it would be very
          # difficult to implement this behavior and this is something of an
          # edge case, so we can tolerate it.
          it "updates the dependency"

        end

      end

      context "and the cookbook is a dep of another cookbook" do

        context "and there is a newer version that matches the other cookbook's constraint" do

          it "updates the cookbook"

        end

        context "and there is a newer version but it doesn't match the other cookbook's constraint" do

          it "does not update the cookbook"

          it "explains why dependency conflicts prevented the update"

        end

      end

    end


  end

end

