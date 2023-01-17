# frozen_string_literal: true
require 'fakefs/spec_helpers'

require './app/test_data'

# rubocop:disable Metrics/BlockLength
RSpec.describe TestData do
  include FakeFS::SpecHelpers

  describe '#test_runs_by_id' do
    let(:fake_git_hash) { 'fake-git-hash' }
    let(:test_id) { './spec/some_spec.rb[1:1:1:1]' }

    let(:test_json) do
      JSON.generate(
        {
          version: '3.12.0',
          examples: [
            {
              id: test_id,
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

    before do
      @local_run_id = TestData.new.import(test_json, fake_git_hash)
    end

    it 'returns [] for a bogus test id' do
      expect(TestData.new.test_runs_by_id('bogus_test_id')).to eq([])
    end

    it 'retrieves the test run data' do
      expect(TestData.new.test_runs_by_id(test_id)).to eq(
        [
          Example.new(
            local_run_id: @local_run_id,
            id: test_id,
            description: 'is tested',
            full_description: 'SomeClass#method is tested',
            status: 'passed',
            file_path: './spec/some_spec.rb',
            line_number: 13,
            run_time: 0.011690498,
            pending_message: nil,
          )
        ]
      )
    end
  end
end
# rubocop:enable Metrics/BlockLength
