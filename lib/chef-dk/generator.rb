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

  module Generator

    class Context
      attr_accessor :have_git
      attr_accessor :app_root
      attr_accessor :cookbook_root
      attr_accessor :app_name
      attr_accessor :cookbook_name
      attr_accessor :new_file_basename
      attr_accessor :content_source
      attr_accessor :author_name
      attr_accessor :author_email
      attr_accessor :license
      attr_accessor :license_description
      attr_accessor :license_text
      attr_accessor :repo_root
      attr_accessor :repo_name
      attr_accessor :cli_config
      attr_accessor :skip_git_init
      attr_accessor :copyright_holder
      attr_accessor :email
      attr_accessor :policy_only
    end

    def self.reset
      @context = nil
    end

    def self.context
      @context ||= Context.new
    end

    module TemplateHelper

      def self.delegate_to_app_context(name)
        define_method(name) do
          ChefDK::Generator.context.public_send(name)
        end
      end

      def year
        Time.now.year
      end

      # delegate all the attributes of app_config
      delegate_to_app_context :app_root
      delegate_to_app_context :cookbook_root
      delegate_to_app_context :cookbook_name
      delegate_to_app_context :new_file_basename
      delegate_to_app_context :content_source
      delegate_to_app_context :author_name
      delegate_to_app_context :author_email
      delegate_to_app_context :email
      delegate_to_app_context :license
      delegate_to_app_context :license_description
      delegate_to_app_context :license_text
      delegate_to_app_context :repo_root
      delegate_to_app_context :repo_name
      delegate_to_app_context :copyright_holder
      delegate_to_app_context :cli_config
      delegate_to_app_context :policy_only
    end

  end
end
