require 'simplecov'
SimpleCov.start 'rails'

ENV["RAILS_ENV"] ||= 'test'

require 'rubygems'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'thinking_sphinx/test'
require 'database_cleaner'
require 'chronic'
require 'fakeweb'
require 'capybara/rspec'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/fixtures/models/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/fixtures/db/*.rb")].each { |f| require f }

RSpec.configure do |config|  
  config.use_transactional_fixtures                 = false
  config.infer_base_class_for_anonymous_controllers = true

  config.include ActionView::TestCase::Behavior, example_group: { file_path: %r{spec/presenters} }  
  config.include FactoryGirl::Syntax::Methods
  config.include AdminResource::Helpers
  config.include ThinkingSphinxHelpers
  config.include RemoteStubs
  config.include LyrisXMLResponse
  config.include DatePathHelper
  config.include StubTime
  config.include StubPublishingCallbacks
  config.include FormFillers
  config.include AuthenticationHelper
  
  config.before :suite do
    DatabaseCleaner.clean_with :truncation
    load "#{Rails.root}/db/seeds.rb"
    DatabaseCleaner.strategy = :transaction
    FactoryGirl.reload
    migration = -> { FixtureMigration.new.up }
    silence_stream STDOUT, &migration
    Dir[Rails.root.join("spec/fixtures/models/*.rb")].each { |f| load f }
    ThinkingSphinx::Test.start_with_autostop
  end
  
  config.before :each do
    FakeWeb.load_callback
    DatabaseCleaner.start
    ActionMailer::Base.deliveries = []
  end
  
  config.after :each do
    DatabaseCleaner.clean
    Rails.cache.clear
  end

  config.after :suite do
    # Just incase
    FileUtils.rm_rf Rails.application.config.scpr.media_root.join("audio/upload")
  end
end
