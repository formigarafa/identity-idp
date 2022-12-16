# frozen_string_literal: true

require 'json'
require 'securerandom'

require_relative 'run_data'

# Top-level class for accessing the test data
class TestData
  def initialize
    @test_data_directory = 'test-data'
  end

  def run_ids
    Dir.glob("#{@test_data_directory}/*").map do |test_dir|
      test_dir.split('/')[2]
    end
  end

  def import(rspec_json)
    test_id = SecureRandom.uuid
    FileUtils.mkdir_p("#{@test_data_directory}/#{test_id}")
    File.open(
      "#{@test_data_directory}/#{test_id}/rspec-out.json",
      'w',
    ) do |file|
      file.write(rspec_json)
    end
    test_id
  end

  def run_data(run_id)
    RunData.from_json(File.read("#{@test_data_directory}/#{run_id}/rspec-out.json"))
  end
end
