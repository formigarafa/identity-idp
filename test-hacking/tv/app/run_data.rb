# frozen_string_literal: true

# Data from one RSpec run
class RunData
  attr_reader :version, :summary_line, :summary, :examples

  def self.from_json(run_json)
    run = JSON.parse(run_json)
    examples = run['examples']

    RunData.new(version: run['version'],
                summary_line: run['summary_line'],
                summary: run['summary'],
                examples: examples)
  end

  def initialize(version: nil,
                 summary_line: nil,
                 summary: nil,
                 examples: [])
    @version = version
    @summary_line = summary_line
    @summary = summary
    @examples = examples
  end
end
