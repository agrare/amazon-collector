require "amazon/collector"
require 'aws-sdk'
require 'aws-sdk-cloudformation'
require "rspec"
require_relative 'aws_stubs'
require_relative 'spec_helper'

RSpec.describe Amazon::Collector do
  include AwsStubs

  it "collects and parses vms" do
    parser = collect_and_parse(:vms)

    expect(format(:vms, parser)).to(
      match_array(
        [{:source_ref  => "instance_0",
          :uid_ems     => "instance_0",
          :name        => "instance_0",
          :power_state => "on",
          :flavor      =>
            {:inventory_collection_name => :flavors,
             :reference                 => {:source_ref => "m3.medium"},
             :ref                       => :manager_ref}},
         {:source_ref  => "instance_ec2_0",
          :uid_ems     => "instance_ec2_0",
          :name        => "instance_ec2_0",
          :power_state => "on",
          :flavor      =>
            {:inventory_collection_name => :flavors,
             :reference                 => {:source_ref => "m3.medium"},
             :ref                       => :manager_ref}},
         {:source_ref  => "instance_0",
          :uid_ems     => "instance_0",
          :name        => "instance_0",
          :power_state => "on",
          :flavor      =>
            {:inventory_collection_name => :flavors,
             :reference                 => {:source_ref => "m3.medium"},
             :ref                       => :manager_ref}},
         {:source_ref  => "instance_ec2_0",
          :uid_ems     => "instance_ec2_0",
          :name        => "instance_ec2_0",
          :power_state => "on",
          :flavor      =>
            {:inventory_collection_name => :flavors,
             :reference                 => {:source_ref => "m3.medium"},
             :ref                       => :manager_ref}}]
      )
    )
  end

  it "collects and parses volumes" do
    parser = collect_and_parse(:volumes)

    # require 'byebug'; byebug
    expect(format(:volumes, parser)).to(
      match_array(
        [{:source_ref        => "volume_id_0",
          :name              => "volume_0",
          :state             => "in-use",
          :size              => 1073741824,
          :source_created_at => Time.parse("2019-02-20 09:53:48 UTC").utc,
          :volume_type       =>
            {:inventory_collection_name => :volume_types,
             :reference                 => {:source_ref => "standard"},
             :ref                       => :manager_ref},
          :source_region     =>
            {:inventory_collection_name => :source_regions,
             :reference                 => {:source_ref => "us-east-1"},
             :ref                       => :manager_ref}},
         {:source_ref        => "volume_id_0",
          :name              => "volume_0",
          :state             => "in-use",
          :size              => 1073741824,
          :source_created_at => Time.parse("2019-02-20 09:53:48 UTC").utc,
          :volume_type       =>
            {:inventory_collection_name => :volume_types,
             :reference                 => {:source_ref => "standard"},
             :ref                       => :manager_ref},
          :source_region     =>
            {:inventory_collection_name => :source_regions,
             :reference                 => {:source_ref => "us-west-1"},
             :ref                       => :manager_ref}}]
      )
    )
  end


  def collect_and_parse(entity)
    parser = Amazon::Parser.new
    with_aws_stubbed(stub_responses) do
      Amazon::Collector.new("source", "access_key_id", "secret_access_key").
        send(:process_entity, entity, parser, 1)
    end
    parser
  end

  def format(entity, parser)
    parser.collections[entity].data.map(&:to_hash)
  end

  def with_aws_stubbed(stub_responses_per_service)
    stub_responses_per_service.each do |service, stub_responses|
      raise "Aws.config[#{service}][:stub_responses] already set" if Aws.config.fetch(service, {})[:stub_responses]
      Aws.config[service]                  ||= {}
      Aws.config[service][:stub_responses] = stub_responses
    end
    yield
  ensure
    stub_responses_per_service.keys.each do |service|
      Aws.config[service].delete(:stub_responses)
    end
  end

  def stub_responses
    {
      :ec2            => {
        :describe_regions            => mocked_regions,
        :describe_availability_zones => mocked_availability_zones,
        :describe_instances          => mocked_instances,
        :describe_key_pairs          => mocked_key_pairs,
        :describe_images             => mocked_images,
        :describe_vpcs               => mocked_vpcs,
        :describe_subnets            => mocked_subnets,
        :describe_security_groups    => mocked_security_groups,
        :describe_network_interfaces => mocked_network_ports,
        :describe_addresses          => mocked_floating_ips,
        :describe_volumes            => mocked_cloud_volumes,
        :describe_snapshots          => mocked_cloud_volume_snapshots,
      },
      :cloudformation => {
        :describe_stacks      => mocked_stacks,
        :list_stack_resources => mocked_stack_resources
      }
    }
  end
end
