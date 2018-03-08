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

require "fileutils"
require "tmpdir"

module TestHelpers

  # A globally accessible place where we can put some state to verify that a
  # test performed a certain operation.
  def self.test_state
    @test_state ||= {}
  end

  def self.reset!
    @test_state = nil
  end

  def test_state
    TestHelpers.test_state
  end

  def fixtures_path
    File.expand_path(File.dirname(__FILE__) + "/unit/fixtures/")
  end

  def project_root
    File.expand_path("../..", __FILE__)
  end

  def reset_tempdir
    clear_tempdir
    FileUtils.mkdir_p(tempdir)
  end

  def clear_tempdir
    FileUtils.rm_rf(tempdir)
    @tmpdir = nil
  end

  def tempdir
    @tmpdir ||= Dir.mktmpdir("chef-dk")
    File.realpath(@tmpdir)
  end

  class TestUI

    attr_reader :output_stream

    def initialize
      @output_stream = StringIO.new
    end

    def err(message)
      @output_stream.puts(message)
    end

    def msg(message)
      @output_stream.puts(message)
    end

    def print(message)
      @output_stream.print(message)
    end

    def output
      @output_stream.string
    end
  end
end
