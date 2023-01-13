# frozen_string_literal: true

require 'fakefs/spec_helpers'

require './app/test_data'

# rubocop:disable Metrics/BlockLength
RSpec.describe TestData do
  describe '#local_run_ids' do
    include FakeFS::SpecHelpers

    context 'with a non-existent data directory' do
      it 'shows no data' do
        expect(TestData.new.local_run_ids).to eq([])
      end
    end

    context 'with an empty data directory' do
      before { Dir.mkdir 'test-data' }

      it 'shows no data' do
        expect(TestData.new.local_run_ids).to eq([])
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
        expect(TestData.new.local_run_ids).to match_array(test_ids)
      end
    end
  end
end
# rubocop:enable Metrics/BlockLength
