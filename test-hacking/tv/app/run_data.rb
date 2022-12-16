# frozen_string_literal: true

# Data from one RSpec run
class RunData
  attr_reader :version

  def self.from_json(run_json)
    run = JSON.parse(run_json)

    RunData.new(version: run['version'])
  end

  def initialize(version:)
    @version = version
  end
end
