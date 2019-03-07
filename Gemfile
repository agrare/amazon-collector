source 'https://rubygems.org'

plugin 'bundler-inject', '~> 1.1'
require File.join(Bundler::Plugin.index.load_paths("bundler-inject")[0], "bundler-inject") rescue nil

gem "activesupport", "~> 5.2.2"
gem "concurrent-ruby"
gem 'manageiq-messaging'
gem "more_core_extensions"
gem "optimist"
gem "rake"
gem "topological_inventory-ingress_api-client", :git => "https://github.com/ManageIQ/topological_inventory-ingress_api-client-ruby", :branch => "master"

group :test do
  gem "rspec"
end

# TODO(lsmola) we should probably list what services exactly we want? (and versions) Since this loads like 50 repos
gem "aws-sdk", "~>3.0.0"
