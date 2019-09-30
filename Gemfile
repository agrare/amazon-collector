source 'https://rubygems.org'

plugin 'bundler-inject', '~> 1.1'
require File.join(Bundler::Plugin.index.load_paths("bundler-inject")[0], "bundler-inject") rescue nil

gem "activesupport", "~> 5.2.2"
gem "cloudwatchlogger", "~> 0.2"
gem "concurrent-ruby"
gem "manageiq-loggers", "~> 0.3.0"
gem 'manageiq-messaging'
gem "more_core_extensions"
gem "optimist"
gem "prometheus_exporter", "~> 0.4.5"
gem "rake"
gem "rest-client", "~>2.0"
gem "sources-api-client",                       :git => "https://github.com/ManageIQ/sources-api-client-ruby", :branch => "master"
gem "topological_inventory-ingress_api-client", :git => "https://github.com/ManageIQ/topological_inventory-ingress_api-client-ruby", :branch => "master"
gem "topological_inventory-providers-common",   :git => "https://github.com/ManageIQ/topological_inventory-providers-common", :branch => "master"
group :test, :development do
  gem "rspec"
  gem "simplecov"
  gem "webmock"
end

# Collector
gem "aws-sdk-ec2", "~>1.102.0"
gem "aws-sdk-cloudformation", "~>1.25.0"
gem "aws-sdk-organizations", "~>1.32.0"
gem "aws-sdk-pricing", "~>1.15.0"
gem "aws-sdk-servicecatalog", "~>1.32.0"

# Event catcher
gem "aws-sdk-sqs", "~>1.20.0"
gem "aws-sdk-sns", "~>1.19.0"
