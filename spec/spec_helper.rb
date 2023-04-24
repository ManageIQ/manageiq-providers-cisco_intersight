if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

Dir[Rails.root.join("spec/shared/**/*.rb")].sort.each { |f| require f }
Dir[File.join(__dir__, "support/**/*.rb")].sort.each { |f| require f }

require "manageiq/providers/cisco_intersight"

VCR.configure do |config|
  config.ignore_hosts('codeclimate.com') if ENV['CI']
  config.cassette_library_dir = File.join(ManageIQ::Providers::CiscoIntersight::Engine.root, 'spec/vcr_cassettes')

  config.configure_rspec_metadata!
  config.default_cassette_options = {
    :match_requests_on            => %i[method uri body],
    :update_content_length_header => true
  }

  secrets = Rails.application.secrets
  secrets.cisco_intersight.each_key do |secret|
    config.filter_sensitive_data(secrets.cisco_intersight_defaults[secret]) { secrets.cisco_intersight[secret] }
  end
end
