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

  module Generator

    # This is here to hold attr_accessor data for Generator context variables
    class Context
      def self.add_attr(name)
        @attributes ||= [ ]

        if !@attributes.include?(name)
          @attributes << name
          attr_accessor(name)
        end
      end

      def self.reset
        return if @attributes.nil?

        @attributes.each do |attr|
          remove_method(attr)
        end

        @attributes = nil
      end
    end

    def self.reset
      @context = nil
    end

    def self.context
      @context ||= Context.new
    end

    def self.add_attr_to_context(name, value = nil)
      sym_name = name.to_sym
      ChefDK::Generator::Context.add_attr(sym_name)
      ChefDK::Generator::TemplateHelper.delegate_to_app_context(sym_name)
      context.public_send("#{sym_name}=", value)
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

      # Prints the short description of the license, suitable for use in a
      # preamble to a file. Optionally specify a comment to prepend to each line.
      def license_description(comment = nil)
        case license
        when "all_rights", "none"
          result = "Copyright:: #{year}, #{copyright_holder}, All Rights Reserved."
        when "apachev2"
          result = <<~EOH
            Copyright:: #{year}, #{copyright_holder}

            Licensed under the Apache License, Version 2.0 (the "License");
            you may not use this file except in compliance with the License.
            You may obtain a copy of the License at

                http://www.apache.org/licenses/LICENSE-2.0

            Unless required by applicable law or agreed to in writing, software
            distributed under the License is distributed on an "AS IS" BASIS,
            WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
            See the License for the specific language governing permissions and
            limitations under the License.
          EOH
        when "mit"
          result = <<~EOH
            The MIT License (MIT)

            Copyright:: #{year}, #{copyright_holder}

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in
            all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
            THE SOFTWARE.
          EOH
        when "gplv2"
          result = <<~EOH
            Copyright:: #{year},  #{copyright_holder}

            This program is free software; you can redistribute it and/or modify
            it under the terms of the GNU General Public License as published by
            the Free Software Foundation; either version 2 of the License, or
            (at your option) any later version.

            This program is distributed in the hope that it will be useful,
            but WITHOUT ANY WARRANTY; without even the implied warranty of
            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
            GNU General Public License for more details.

            You should have received a copy of the GNU General Public License along
            with this program; if not, write to the Free Software Foundation, Inc.,
            51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
          EOH
        when "gplv3"
          result = <<~EOH
            Copyright:: #{year},  #{copyright_holder}

            This program is free software: you can redistribute it and/or modify
            it under the terms of the GNU General Public License as published by
            the Free Software Foundation, either version 3 of the License, or
            (at your option) any later version.

            This program is distributed in the hope that it will be useful,
            but WITHOUT ANY WARRANTY; without even the implied warranty of
            MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
            GNU General Public License for more details.

            You should have received a copy of the GNU General Public License
            along with this program.  If not, see <http://www.gnu.org/licenses/>.
          EOH
        else
          raise ArgumentError, "Invalid generator.license setting: #{license}.  See available licenses at https://docs.chef.io/ctl_chef.html#chef-generate-cookbook"
        end
        if comment
          # Ensure there's no trailing whitespace
          result.gsub(/^(.+)$/, "#{comment} \\1").gsub(/^$/, "#{comment}").strip
        else
          result
        end
      end
    end

  end
end
