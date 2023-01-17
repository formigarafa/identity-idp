RSpec.describe "RunData" do
  subject(:run_data) { RunData.from_json('fake-local-run-id', run_json) }

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

    describe 'the first example' do
      subject(:example) { run_data.examples[0] }

      it 'has the correct id' do
        expect(example.id).to eq('./spec/some_spec.rb[1:1:1:1]')
      end

      it 'has the correct description' do
        expect(example.description).to eq('is tested')
      end

      it 'has the correct full_description' do
        expect(example.full_description).to eq('SomeClass#method is tested')
      end

      it 'has the correct status' do
        expect(example.status).to eq('passed')
      end

      it 'has the correct file_path' do
        expect(example.file_path).to eq('./spec/some_spec.rb')
      end

      it 'has the correct line_number' do
        expect(example.line_number).to eq(13)
      end

      it 'has the correct run_time' do
        expect(example.run_time).to eq(0.011690498)
      end

      it 'has the correct pending_message' do
        expect(example.pending_message).to eq(nil)
      end
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
