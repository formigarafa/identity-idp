require 'sinatra'
require 'gruff'

require_relative 'app/test_data'

test_times = []
TestData.new.run_ids.each do |run_id|
  TestData.new.run_data(run_id).examples.each do |example_run|
    test_times.push(example_run.run_time)
  end
end

get '/' do
  g = Gruff::Histogram.new
  g.title = 'Tests by Time'

  g.hide_legend = true
  g.hide_title = true

  g.minimum_bin = test_times.max / 10
  g.maximum_bin = test_times.max
  g.bin_width = test_times.max / 10

  g.data :Time, test_times
  g.labels = [1, 1.1, 2, 3, 4, 5, 6,]
  g.write('tmpfile.png')

  content_type 'image/png'
  File.read('tmpfile.png')
end
