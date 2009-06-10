$: << File.dirname(__FILE__)+'/../lib'

require 'rr'
Spec::Runner.configure do |config|
  config.mock_with RR::Adapters::Rspec
end