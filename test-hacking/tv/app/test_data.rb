# frozen_string_literal: true

require 'json'
require 'securerandom'

require_relative 'run_data'

# Top-level class for accessing the test data
class TestData
  def initialize
    @test_data_directory = 'test-data'
  end

  def local_run_ids
    Dir.glob("#{@test_data_directory}/*").map do |test_dir|
      test_dir.split('/')[-1]
    end
  end

  def import(rspec_json, git_hash)
    test_run_id = SecureRandom.uuid
    FileUtils.mkdir_p("#{@test_data_directory}/#{test_run_id}")
    File.open(
      "#{@test_data_directory}/#{test_run_id}/rspec-out.json",
      'w',
    ) do |file|
      file.write(rspec_json)
    end

    File.open(
      "#{@test_data_directory}/#{test_run_id}/metada.json",
      'w',
    ) do |file|
      file.puts "{ \"git_hash\": \"#{git_hash}\" }"
    end

    test_run_id
  end

  def import_gitlab_run(directory)
    git_hash = directory.split('/')[-1]
    import(File.open("#{directory}/rspec.json").read, git_hash)
  end

  def run_data(local_run_id)
    RunData.from_json(
      local_run_id,
      File.read("#{@test_data_directory}/#{local_run_id}/rspec-out.json"),
    )
  end

  def test_runs_by_id(test_id)
    return_value = []

    local_run_ids.each do |run_id|
      return_value += run_data(run_id).test_runs_for_id(test_id)
    end

    return_value
  end
end
