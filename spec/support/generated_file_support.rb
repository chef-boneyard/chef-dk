
require 'spec_helper'
require 'rspec/expectations'

RSpec::Matchers.define :have_line do |expected_line|

  match do |filename|
    lines = File.read(filename).split("\n")
    lines.find { |line| line.match(expected_line) }
  end

end
