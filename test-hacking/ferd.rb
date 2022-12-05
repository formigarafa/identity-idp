require 'rspec'

runner = RSpec::Core::Runner.new(RSpec::Core::ConfigurationOptions.new(['spec']))

puts "loading"
runner.setup($stdout, $stderr)
puts "done"

# puts runner.methods - Object.new.methods

puts "configuration: #{runner.configuration}"
puts "options: #{options}"
