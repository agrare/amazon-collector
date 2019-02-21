require "concurrent"
require "amazon/connection"
require "amazon/collector/cloud_formation"
require "amazon/collector/ec2"
require "amazon/collector/pricing"
require "amazon/collector/service_catalog"
require "amazon/parser"
require "amazon/iterator"
require "topological_inventory-ingress_api-client"

module Amazon
  class Collector
    include Amazon::Collector::CloudFormation
    include Amazon::Collector::Ec2
    include Amazon::Collector::Pricing
    include Amazon::Collector::ServiceCatalog

    def initialize(source, access_key_id, secret_access_key, batch_size: 1_000, poll_time: 5)
      self.batch_size        = batch_size
      self.collector_threads = Concurrent::Map.new
      self.finished          = Concurrent::AtomicBoolean.new(false)
      self.log               = Logger.new(STDOUT)
      self.secret_access_key = secret_access_key
      self.access_key_id     = access_key_id
      self.poll_time         = poll_time
      self.queue             = Queue.new
      self.source            = source
    end

    def collect!
      parser = Amazon::Parser.new
      count  = 1

      entity_types.each do |entity_type|
        log.info("Starting collection for #{entity_type}...")
        parser, count = process_entity(entity_type, parser, count)
      end

      save_or_increment(parser, :rest)
    end

    def stop
      finished.value = true
    end

    private

    attr_accessor :batch_size, :collector_threads, :finished, :log,
                  :secret_access_key, :access_key_id, :poll_time, :queue, :source

    def finished?
      finished.value
    end

    def process_entity(entity_type, starting_parser, starting_count)
      parser = starting_parser
      count  = starting_count

      all_manager_uuids = []

      ec2_connection(:region => "us-east-1").client.describe_regions.regions.each do |region|
        scope = {:region => region.region_name}

        send(entity_type.to_s, scope).each do |entity|
          all_manager_uuids << parser.send("parse_#{entity_type}", entity, scope)

          parser, count = save_or_increment(parser, count)
        end
      end

      parser.collections[entity_type.to_sym].all_manager_uuids = all_manager_uuids

      return parser, count
    end

    def save_or_increment(parser, count)
      if count == :rest || count >= batch_size
        log.info("Sending batch to to persister queue...")
        save_inventory(parser.collections.values)

        # And and create new persistor so the old one with data can be GCed
        return_parser = Amazon::Parser.new
        return_count  = 1
      else
        return_parser = parser
        return_count  = count + 1
      end

      return return_parser, return_count
    end

    def save_inventory(collections)
      return if collections.empty?

      ingress_api_client.save_inventory(
        :inventory => TopologicalInventoryIngressApiClient::Inventory.new(
          :name        => "OCP",
          :schema      => TopologicalInventoryIngressApiClient::Schema.new(:name => "Default"),
          :source      => source,
          :collections => collections,
        )
      )
    end

    def entity_types
      endpoint_types.flat_map { |endpoint| send("#{endpoint}_entity_types") }
    end

    def cloud_formations_entity_types
      %w(orchestrations_stacks)
    end

    def ec2_entity_types
      %w(source_regions vms volumes)
    end

    def service_catalog_entity_types
      %w(service_offerings service_instances service_plans)
    end

    def endpoint_types
      %w(pricing ec2 service_catalog)
    end

    def pricing_entity_types
      %w(flavors volume_types)
    end

    def connection_for_entity_type(entity_type, scope)
      endpoint_types.each do |endpoint|
        return send("#{endpoint}_connection", scope) if send("#{endpoint}_entity_types").include?(entity_type)
      end
      nil
    end

    def connection_attributes
      {:access_key_id => access_key_id, :secret_access_key => secret_access_key}
    end

    def service_catalog_connection(scope)
      Amazon::Connection.service_catalog(connection_attributes.merge(scope))
    end

    def ec2_connection(scope)
      Amazon::Connection.ec2(connection_attributes.merge(scope))
    end

    def pricing_connection(scope)
      Amazon::Connection.pricing(connection_attributes.merge(scope))
    end

    def cloud_formation_connection(scope)
      Amazon::Connection.cloud_formation(connection_attributes.merge(scope))
    end

    def ingress_api_client
      TopologicalInventoryIngressApiClient::DefaultApi.new
    end
  end
end
