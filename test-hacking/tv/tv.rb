require 'sinatra'
require 'gruff'

require_relative 'app/test_data'

all_spec_types = []
TestData.new.run_ids.each do |run_id|
  TestData.new.run_data(run_id).examples.each do |example_run|
    all_spec_types.push(example_run.file_path.split('/')[2].to_sym)
  end
end
all_spec_types.uniq!

def test_times(spec_types)
  test_times = []
  TestData.new.run_ids.each do |run_id|
    TestData.new.run_data(run_id).examples.each do |example_run|
      if spec_types.include?(example_run.spec_type)
        test_times.push(example_run.run_time)
      end
    end
  end
  test_times
end

get '/' do
  spec_types = []
  all_spec_types.each do |spec_type|
    spec_types.push(spec_type) if params[spec_type]
  end

  spec_types = all_spec_types if spec_types.empty?

  erb :graph,
      layout: :tv_layout,
      locals: {
        spec_types: spec_types,
        all_spec_types: all_spec_types
      }
end

get '/test-by-time' do
  if params['spec_types']
    spec_types = params['spec_types'].split(',').map(&:to_sym)
  else
    spec_types = all_spec_types
  end

  g = Gruff::Histogram.new
  g.title = params['title'] || 'Tests by Time'

  g.hide_legend = true
  g.hide_title = true
  g.hide_labels = true

  g.minimum_bin = test_times(spec_types).max / 10
  g.maximum_bin = test_times(spec_types).max
  g.bin_width = test_times(spec_types).max / 10

  g.data :Time, test_times(spec_types)

  i = g.to_image
  i.format = 'PNG'

  content_type 'image/png'
  i.to_blob
end
