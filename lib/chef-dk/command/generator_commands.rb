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
  module Command
    module GeneratorCommands

      def self.build(class_name, params)
        const_get(class_name).new(params)
      end

      class Base
        include Mixlib::CLI

        attr_reader :params

        def initialize(params)
          super()
          @params = params
        end

        def chef_runner
          @chef_runner ||= ChefRunner.new(cookbook_path, ["code_generator::#{recipe}"])
        end

        def cookbook_path
          File.expand_path("../../skeletons", __FILE__)
        end

        def setup_app
          Generator.app.root = File.join(Dir.pwd, "demo-#{Time.now.to_i}") #FIXME
        end

      end

      # chef generate cookbook path/to/basename --skel=path/to/skeleton --example
      class Cookbook < Base

        banner "Usage: chef generate cookbook NAME [options]"

        attr_reader :errors

        def initialize(params)
          super
        end

        def run
          setup_app
          chef_runner.converge
        end

        def recipe
          "cookbook"
        end

      end
    end
  end
end

