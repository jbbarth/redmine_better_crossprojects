ENV["RAILS_ENV"] ||= 'test'

#rails env
require File.expand_path('../../../../config/environment', __FILE__)

#test gems
require 'rspec/autorun'
require 'rspec/mocks'
require 'rspec/mocks/standalone'
require 'rspec/rails'
require 'pry'

#load paths
$:.<< File.expand_path('../../app/models', __FILE__)
$:.<< File.expand_path('../../lib', __FILE__)

#rspec base config
RSpec.configure do |config|
  config.mock_with :rspec
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true
  config.fixture_path = File.expand_path('../../../../test/fixtures', __FILE__)
end
