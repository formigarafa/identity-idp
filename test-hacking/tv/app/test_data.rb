# frozen_string_literal: true

require 'json'
require 'securerandom'

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

  def import(run_json)
    test_id = SecureRandom.uuid
    FileUtils.mkdir_p
    ("#{@test_data_directory}/#{test_id}")
    test_id
  end
end
