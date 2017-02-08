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

require "chef/dsl/recipe"

module ChefDK

  # Methods here are mixed in to the Chef recipe DSL to provide extra
  # functionality for generator cookbooks.
  module RecipeDSLExt

    # Replaces the current formatter (by default this is the `doc` formatter)
    # with the null formatter, thus suppressing normal Chef output.
    def silence_chef_formatter
      old = run_context.events.subscribers.first
      out, err = old.output.out, old.output.err
      run_context.events.subscribers.clear
      null_formatter = Chef::Formatters.new(:null, out, err)
      run_context.events.register(null_formatter)
    end

  end
end

Chef::DSL::Recipe.send(:include, ChefDK::RecipeDSLExt)
