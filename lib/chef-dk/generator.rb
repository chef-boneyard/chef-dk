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

    class AppConfig
      attr_accessor :root
      attr_accessor :cookbook_name
      attr_accessor :author_name
      attr_accessor :author_email
      attr_accessor :license_description
      attr_accessor :license_text
    end

    def self.app
      @app ||= AppConfig.new
    end

    module TemplateHelper

      def self.delegate_to_app_config(name)
        define_method(name) do
          ChefDK::Generator.app.public_send(name)
        end
      end

      # delegate all the attributes of app_config
      delegate_to_app_config :root
      delegate_to_app_config :cookbook_name
      delegate_to_app_config :author_name
      delegate_to_app_config :author_email
      delegate_to_app_config :license_description
      delegate_to_app_config :license_text

    end

  end
end
