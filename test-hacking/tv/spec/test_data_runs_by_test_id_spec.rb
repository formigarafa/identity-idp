# frozen_string_literal: true
require 'fakefs/spec_helpers'

require './app/test_data'

# rubocop:disable Metrics/BlockLength
RSpec.describe TestData do
  describe '#test_runs_by_id' do
    let(:test_json) do
      JSON.generate(
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
    end

    let(:test_id) do
      TestData.new.import(test_json)
    end

    xit 'returns nil for a bogus test id' do
      expect(TestData.new.test_runs_by_id('bogus-test-id')).to be(nil)
    end

    xit 'retrieves the test run data' do
      expect(TestData.new.test_runs_by_id('./spec/some_spec.rb[1:1:1:1]')).not_to be(nil)
    end
  end
end
# rubocop:enable Metrics/BlockLength
