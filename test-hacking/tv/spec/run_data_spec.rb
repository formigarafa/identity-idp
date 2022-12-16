RSpec.describe "RunData" do
  subject(:run_data) { RunData.from_json(run_json) }

  let(:run_json) do
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
      }
    )
  end

  context 'with some JSON data' do
    it "has the correct version" do
      expect(run_data.version).to eq('3.12.0')
    end

    it 'has the correct summary line' do
      expect(run_data.summary_line).to eq('3 examples, 0 failures')
    end

    it 'has the correct summary' do
      # ToDo: switch key strings over to keywords
      expect(run_data.summary).to eq(
        {
          'duration' => 0.020395725,
          'example_count' => 1,
          'failure_count' => 0,
          'pending_count' => 0,
          'errors_outside_of_examples_count' => 0,
        }
      )
    end

    it 'has one examples' do
      expect(run_data.examples.size).to eq(1)
    end
  end

  context 'with different JSON data' do
    let(:run_json) do
      JSON.generate(
        {
          version: '4.13.1',
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
        }
      )
    end

    it "has the correct version" do
      expect(run_data.version).to eq('4.13.1')
    end
  end
end
