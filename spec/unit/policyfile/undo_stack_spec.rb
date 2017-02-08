#
# Copyright:: Copyright (c) 2015 Chef Software Inc.
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
require "chef-dk/policyfile/undo_stack"

describe ChefDK::Policyfile::UndoStack do

  let(:chefdk_home) { File.join(tempdir, "chefdk_home", ".chefdk") }

  let(:policy_revision) do
    {
      "name" => "appserver",
      "revision_id" => "1111111111111111111111111111111111111111111111111111111111111111",
    }
  end

  let(:undo_record) do
    ChefDK::Policyfile::UndoRecord.new.tap do |undo_record|
      undo_record.add_policy_group("preprod")
      undo_record.add_policy_revision("appserver", "preprod", policy_revision)
    end
  end

  # Probably takes a Chef::Config as an arg?
  subject(:undo_stack) { described_class.new }

  let(:expected_undo_dir) { File.join(chefdk_home, "undo") }

  def undo_stack_files
    Dir[File.join(expected_undo_dir, "*")]
  end

  before do
    clear_tempdir
    allow(ChefDK::Helpers).to receive(:chefdk_home).and_return(chefdk_home)
  end

  after(:all) do
    clear_tempdir
  end

  it "uses chefdk_home to infer the location of the undo directory" do
    expect(undo_stack.undo_dir).to eq(expected_undo_dir)
  end

  context "when there are no undo records" do

    it "has zero items" do
      expect(undo_stack.size).to eq(0)
    end

    it "is empty" do
      expect(undo_stack).to be_empty
    end

    it "has no items to iterate over" do
      expect { |b| undo_stack.each_with_id(&b) }.to_not yield_control
    end

    it "has an empty list of undo records" do
      expect(undo_stack.undo_records).to eq([])
    end

    it "raises an error when attempting to pop an item from the stack" do
      expect { undo_stack.pop }.to raise_error(ChefDK::CantUndo)
    end

    describe "pushing an undo record" do

      before do
        expect(File.exist?(chefdk_home)).to be(false)
        expect(File.exist?(expected_undo_dir)).to be(false)

        undo_stack.push(undo_record)
      end

      it "creates the undo directory" do
        expect(File.exist?(chefdk_home)).to be(true)
        expect(File.exist?(expected_undo_dir)).to be(true)
      end

      it "creates the undo record" do
        expect(undo_stack_files.size).to eq(1)

        undo_record_json = IO.read(undo_stack_files.first)
        undo_record_data = FFI_Yajl::Parser.parse(undo_record_json)
        expect(undo_record_data).to eq(undo_record.for_serialization)
      end

    end

  end

  context "when there is one undo record" do

    # `Time.new` is stubbed later on, need to force it to be evaluated before
    # then.
    let!(:start_time) { Time.new }

    let(:expected_id) { start_time.utc.strftime("%Y%m%d%H%M%S") }

    let(:missing_id) { (start_time + 1).utc.strftime("%Y%m%d%H%M%S") }

    before do
      allow(Time).to receive(:new).and_return(start_time)
      undo_stack.push(undo_record)
    end

    it "creates the item on disk" do
      expect(File).to be_directory(undo_stack.undo_dir)
      expect(undo_stack_files.size).to eq(1)
    end

    it "has one item" do
      expect(undo_stack.size).to eq(1)
    end

    it "is not empty" do
      expect(undo_stack).to_not be_empty
    end

    it "checks whether a record exists by id" do
      expect(undo_stack).to have_id(expected_id)
      expect(undo_stack).to_not have_id(missing_id)
    end

    it "deletes a record by id" do
      expect(undo_stack.delete(expected_id)).to eq(undo_record)
    end

    it "deletes a record by id and yields it" do
      expect { |b| undo_stack.delete(expected_id, &b) }.to yield_with_args(undo_record)
    end

    it "fails to delete a record that doesn't exist" do
      expect { undo_stack.delete(missing_id) }.to raise_error(ChefDK::UndoRecordNotFound)
    end

    it "pops the last record" do
      expect(undo_stack.pop).to eq(undo_record)
    end

    it "pops the last record and yields it" do
      expect { |b| undo_stack.pop(&b) }.to yield_with_args(undo_record)
    end

    it "iterates over the records" do
      expect { |b| undo_stack.each_with_id(&b) }.to yield_successive_args([expected_id, undo_record])
    end

    it "has the undo record that was pushed" do
      expect(undo_stack.undo_records.size).to eq(1)
      expect(undo_stack.undo_records).to eq( [ undo_record ] )
    end

    context "and the record is removed" do

      let!(:popped_record) { undo_stack.pop }

      it "has no items" do
        expect(undo_stack_files.size).to eq(0)
      end

    end

  end

  context "when the stack is at the maximum configured size" do
    # `Time.new` is stubbed later on, need to force it to be evaluated before
    # then.
    let!(:start_time) { Time.new }

    def next_time
      @increment ||= 0
      @increment += 1

      start_time + @increment
    end

    def incremented_undo_record(i)
      record = {
        "name" => "appserver",
        "revision_id" => i.to_s * 64,
      }

      ChefDK::Policyfile::UndoRecord.new.tap do |undo_record|
        undo_record.description = "delete-policy-group preprod-#{i}"
        undo_record.add_policy_group("preprod-#{i}")
        undo_record.add_policy_revision("appserver", "preprod-#{i}", record)
      end
    end

    before do
      ##  # UndoStack assumes you're not creating more than 1 undo record/second,
      ##  # which is reasonable in the real world but won't work here.
      allow(Time).to receive(:new) { next_time }

      10.times { |i| undo_stack.push(incremented_undo_record(i)) }

      expect(undo_stack_files.size).to eq(10)
    end

    describe "pushing a new undo record" do
      it "does not exceed the maximum size" do
        undo_stack.push(incremented_undo_record(11))

        expect(undo_stack_files.size).to eq(10)
      end

      it "removes the oldest record" do
        oldest_record_file = undo_stack_files.sort.first

        undo_stack.push(incremented_undo_record(11))

        expect(File.exist?(oldest_record_file)).to be(false)
      end
    end

    context "when the stack is above maximum configured size" do

      let(:older_record_path) do
        record_id = (Time.new - (3600 * 24)).utc.strftime("%Y%m%d%H%M%S")
        File.join(expected_undo_dir, record_id)
      end

      before do
        FileUtils.touch(older_record_path)
        expect(undo_stack_files.size).to eq(11)
      end

      describe "pushing a new undo record" do
        it "does not exceed the maximum size" do
          undo_stack.push(incremented_undo_record(11))

          expect(undo_stack_files.size).to eq(10)
        end

        it "removes the oldest record" do
          oldest_record_file = undo_stack_files.sort.first

          undo_stack.push(incremented_undo_record(11))

          expect(File.exist?(oldest_record_file)).to be(false)
        end
      end

    end
  end

end
