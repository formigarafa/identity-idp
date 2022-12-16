# frozen_string_literal: true

require 'fakefs/spec_helpers'

require './app/test_data'

# rubocop:disable Metrics/BlockLength
RSpec.describe TestData do
  describe '#run_ids' do
    include FakeFS::SpecHelpers

    context 'with a non-existent data directory' do
      it 'shows no data' do
        expect(TestData.new.run_ids).to eq([])
      end
    end

    context 'with an empty data directory' do
      before { Dir.mkdir 'test-data' }

      it 'shows no data' do
        expect(TestData.new.run_ids).to eq([])
      end
    end

    context 'with a couple of test runs' do
      let(:test_ids) do
        [
          '0eb55661-0355-48db-97ac-f3aefc4ec22b',
          '0247035a-ff95-4986-be04-ce0fe775adad',
        ]
      end

      before do
        Dir.mkdir 'test-data'
        test_ids.each { |id| Dir.mkdir("test-data/#{id}") }
      end

      it 'shows the test runs' do
        expect(TestData.new.run_ids).to match_array(test_ids)
      end
    end
  end

  describe '#import' do
    include FakeFS::SpecHelpers

    let(:test_id) do
      TestData.new.import(
        JSON.generate(
          {
            "version": "3.12.0",
            "examples": [
              {
                "id": "./spec/some_spec.rb[1:1:1:1]",
                "description": "is tested",
                "full_description": "SomeClass#method is tested",
                "status": "passed",
                "file_path": "./spec/some_spec.rb",
                "line_number": 13,
                "run_time": 0.011690498,
                "pending_message": nil
              }
            ],
            "summary": {
              "duration": 0.020395725,
              "example_count": 1,
              "failure_count": 0,
              "pending_count": 0,
              "errors_outside_of_examples_count": 0
            },
            "summary_line": "3 examples, 0 failures"
          }
        )
      )
    end

    it 'creates the test data file' do
      expect(Dir.exist?("test-data/#{test_id}")).to be true
    end
  end
end
# rubocop:enable Metrics/BlockLength
