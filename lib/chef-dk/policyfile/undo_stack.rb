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

require "fileutils"

require "ffi_yajl"

require "chef-dk/helpers"
require "chef-dk/policyfile/undo_record"

module ChefDK
  module Policyfile

    class UndoStack

      MAX_SIZE = 10

      include Helpers

      def undo_dir
        File.join(Helpers.chefdk_home, "undo")
      end

      def size
        undo_record_files.size
      end

      def empty?
        size == 0
      end

      def has_id?(id)
        File.exist?(undo_file_for(id))
      end

      def each_with_id
        undo_record_files.each do |filename|
          yield File.basename(filename), load_undo_record(filename)
        end
      end

      def undo_records
        undo_record_files.map { |f| load_undo_record(f) }
      end

      def push(undo_record)
        ensure_undo_dir_exists

        record_id = Time.new.utc.strftime("%Y%m%d%H%M%S")
        path = File.join(undo_dir, record_id)

        with_file(path) do |f|
          f.print(FFI_Yajl::Encoder.encode(undo_record.for_serialization, pretty: true))
        end

        records_to_delete = undo_record_files.size - MAX_SIZE
        if records_to_delete > 0
          undo_record_files.take(records_to_delete).each do |file|
            File.unlink(file)
          end
        end

        self
      end

      def pop
        file_to_pop = undo_record_files.last
        if file_to_pop.nil?
          raise CantUndo, "No undo records exist in #{undo_dir}"
        end

        record = load_undo_record(file_to_pop)
        # if this hits an exception, we skip unlink
        yield record if block_given?
        File.unlink(file_to_pop)
        record
      end

      def delete(id)
        undo_file = undo_file_for(id)
        unless File.exist?(undo_file)
          raise UndoRecordNotFound, "No undo record for id '#{id}' exists at #{undo_file}"
        end

        record = load_undo_record(undo_file)
        yield record if block_given?
        File.unlink(undo_file)
        record
      end

      private

      def undo_file_for(id)
        File.join(undo_dir, id)
      end

      def load_undo_record(file)
        data = FFI_Yajl::Parser.parse(IO.read(file))
        UndoRecord.new.load(data)
      end

      def undo_record_files
        Dir[File.join(undo_dir, "*")].sort
      end

      def ensure_undo_dir_exists
        return false if File.directory?(undo_dir)

        FileUtils.mkdir_p(undo_dir)
      end
    end

  end
end
