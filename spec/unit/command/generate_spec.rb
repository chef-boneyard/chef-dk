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

require "spec_helper"
require "stringio"
require "chef-dk/command/generate"

class ChefDK::Command::GeneratorCommands::Example < ChefDK::Command::GeneratorCommands::Base

  option :one,
    long:         "--option-one",
    description:  "one"

  option :two,
    long:         "--option-two",
    description:  "two"

  option :arg,
    short:        "-a ARG",
    long:         "--arg ARG",
    description:  "an option that takes an argument"

  def initialize(argv)
    super # required by mixlib-cli
    @argv = argv
  end

  def run
    parse_options(@argv)
    { argv: @argv, ran_cmd: "example" }
  end
end

describe ChefDK::Command::Generate do

  # Use a subclass so we have a clean slate of defined generators
  let(:generator_class) { Class.new(ChefDK::Command::Generate) }

  let(:stdout_io) { StringIO.new }
  let(:stderr_io) { StringIO.new }

  def stdout
    stdout_io.string
  end

  def stderr
    stderr_io.string
  end

  subject(:generate) do
    g = generator_class.new
    allow(g).to receive(:stdout).and_return(stdout_io)
    allow(g).to receive(:stderr).and_return(stderr_io)
    g
  end

  it "has a list of generators" do
    expect(generator_class.generators).to eq([])
  end

  context "with a generator defined" do
    let(:expected_help_message) do
      <<~E
        Usage: chef generate GENERATOR [options]

        Available generators:
          example  this is a test
      E
    end

    before do
      generator_class.generator(:example, :Example, "this is a test")
    end

    it "includes the generator in the list" do
      expect(generator_class.generators.size).to eq(1)
      generator_spec = generator_class.generators.first
      expect(generator_spec.name).to eq(:example)
      expect(generator_spec.class_name).to eq(:Example)
      expect(generator_spec.description).to eq("this is a test")
    end

    it "includes the generator in the help output" do
      expect(generator_class.banner).to eq(expected_help_message)
    end

    it "prints usage when running an unknown generator" do
      generate.run(%w{ancient-aliens})
      expect(stdout).to include(expected_help_message)
    end

    it "runs the generator sub-command" do
      result = generate.run(%w{example})
      expect(result[:ran_cmd]).to eq("example")
    end

    it "removes the subcommand name from argv" do
      result = generate.run(%w{example})
      expect(result[:argv]).to eq([])
    end

    it "passes extra arguments and options to the subcommand" do
      result = generate.run(%w{example argument_one argument_two --option-one --option-two})
      expect(result[:argv]).to eq(%w{argument_one argument_two --option-one --option-two})
    end

    describe "when an invalid option is passed to the subcommand" do

      it "prints usage and returns non-zero" do
        result = generate.run(%w{example --nope})
        expect(result).to eq(1)
        expect(stderr).to eq("ERROR: invalid option: --nope\n\n")
      end

    end

    describe "when an option requires an argument but none is given" do

      it "prints usage and returns non-zero" do
        result = generate.run(%w{example --arg})
        expect(result).to eq(1)
        expect(stderr).to eq("ERROR: missing argument: --arg\n\n")
      end

    end

  end
end
