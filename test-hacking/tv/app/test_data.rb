# frozen_string_literal: true

require 'json'

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
    test_run = RunData.new
    test_run.create_run_directory
    save_rspec_output(test_run.local_test_run_id, rspec_json)
    save_metadata(test_run.local_test_run_id, JSON.generate(git_hash: git_hash))
    test_run.local_test_run_id
  end

  def test_run_directory(local_test_run_id)
    "#{@test_data_directory}/#{local_test_run_id}"
  end

  def rspec_file(local_test_run_id)
    "#{test_run_directory(local_test_run_id)}/rspec.out.json"
  end

  def metadata_file(local_test_run_id)
    "#{test_run_directory(local_test_run_id)}/metada.json"
  end

  def save_rspec_output(local_test_run_id, rspec_json)
    # DEBUG
    puts "Dir.pwd: #{Dir.pwd}"
    puts "Dir.entries('.'): #{Dir.entries('.')}"
    # puts "Dir.entries('test-data'): #{Dir.entries('test-data')}"
    puts "local_test_run_id: #{local_test_run_id}"

    File.open(
      rspec_file(local_test_run_id),
      'w',
    ) do |file|
      file.write(rspec_json)
    end
  end

  def save_metadata(local_test_run_id, metadata)
    File.open(
      metadata_file(local_test_run_id),
      'w',
    ) do |file|
      file.write(metadata)
    end
  end

  def import_gitlab_run(directory)
    git_hash = directory.split('/')[-1]
    import(File.open("#{directory}/rspec.json").read, git_hash)
  end

  def run_data(local_run_id)
    RunData.from_json(
      local_run_id,
      File.read("#{@test_data_directory}/#{local_run_id}/rspec.out.json"),
    )
  end

  def test_runs_by_id(test_id)
    local_run_ids.inject([]) do |return_value, run_id|
      return_value + run_data(run_id).test_runs_for_id(test_id)
    end
  end
end
