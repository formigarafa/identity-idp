# frozen_string_literal: true

require_relative 'example'

# Data from one RSpec run
class RunData
  attr_reader :version, :summary_line, :summary, :examples

  def self.from_json(local_run_id, run_json)
    run = JSON.parse(run_json)
    examples = run['examples'].map do |raw_example|
      Example.new(
        local_run_id: local_run_id,
        id: raw_example['id'],
        description: raw_example['description'],
        full_description: raw_example['full_description'],
        status: raw_example['status'],
        file_path: raw_example['file_path'],
        line_number: raw_example['line_number'],
        run_time: raw_example['run_time'],
        pending_message: raw_example['pending_message'],
      )
    end

    RunData.new(version: run['version'],
                summary_line: run['summary_line'],
                summary: run['summary'],
                examples: examples)
  end

  def initialize(version: nil,
                 summary_line: nil,
                 summary: nil,
                 examples: [],
                 status: nil,
                 file_path: nil)
    @version = version
    @summary_line = summary_line
    @summary = summary
    @examples = examples
  end

  def test_runs_for_id(test_id)
    examples.filter { |example_run| example_run.id == test_id }
  end
end
