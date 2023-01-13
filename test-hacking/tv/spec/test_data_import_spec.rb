# frozen_string_literal: true

require 'fakefs/spec_helpers'

require './app/test_data'

# rubocop:disable Metrics/BlockLength
RSpec.describe TestData do
  describe '#import' do
    include FakeFS::SpecHelpers

    TEST_JSON = JSON.generate(
      {
        version: '3.12.0',
        examples: [
          {
            id: './spec/some_spec.rb[1:1:1:1]',
            description: 'is tested',
            full_description: 'SomeClass#method is tested',
            status: 'passed',
            file_path: './spec/some_spec.rb',
            line_number: 13,
            run_time: 0.011690498,
            pending_message: nil,
          },
        ],
        summary: {
          duration: 0.020395725,
          example_count: 1,
          failure_count: 0,
          pending_count: 0,
          errors_outside_of_examples_count: 0,
        },
        summary_line: '3 examples, 0 failures',
      },
    )

    let(:git_hash) { '678891c3c2f38304efd1ff47deb0d1ba9f4aac88' }

    let(:test_id) do
      TestData.new.import(TEST_JSON, git_hash)
    end

    let(:rspec_data_filename) { "test-data/#{test_id}/rspec-out.json" }

    it 'saves the test data' do
      expect(File.read(rspec_data_filename)).to eq(TEST_JSON)
    end
  end
end
# rubocop:enable Metrics/BlockLength
