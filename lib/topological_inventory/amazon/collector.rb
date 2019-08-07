require "concurrent"
require "topological_inventory-ingress_api-client/collector"
require "topological_inventory/amazon/connection"
require "topological_inventory/amazon/parser"
require "topological_inventory/amazon/iterator"
require "topological_inventory/amazon/logging"
require "topological_inventory-ingress_api-client"

module TopologicalInventory
  module Amazon
    class Collector < ::TopologicalInventoryIngressApiClient::Collector
      include Logging

      require "topological_inventory/amazon/collector/cloud_formation"
      require "topological_inventory/amazon/collector/ec2"
      require "topological_inventory/amazon/collector/pricing"
      require "topological_inventory/amazon/collector/service_catalog"

      include Amazon::Collector::CloudFormation
      include Amazon::Collector::Ec2
      include Amazon::Collector::Pricing
      include Amazon::Collector::ServiceCatalog

      def initialize(source, access_key_id, secret_access_key, metrics, default_limit: 1_000, poll_time: 5)
        super(source,
              :default_limit => default_limit,
              :poll_time     => poll_time)

        self.secret_access_key = secret_access_key
        self.access_key_id     = access_key_id
        self.metrics           = metrics
      end

      def collect!
        loop do
          begin
            entity_types.each do |entity_type|
              process_entity(entity_type)
            end
          rescue => e
            logger.error(e)
            metrics.record_error
          ensure
            sleep(30)
          end
        end
      end

      private

      attr_accessor :log, :metrics, :secret_access_key, :access_key_id

      def process_entity(entity_type)
        parser      = create_parser
        total_parts = 0
        sweep_scope = Set.new([entity_type.to_sym])

        refresh_state_uuid = SecureRandom.uuid
        logger.info("Collecting #{entity_type} with :refresh_state_uuid => '#{refresh_state_uuid}'...")

        count = 0
        ec2_connection(:region => default_region).client.describe_regions.regions.each do |region|
          scope = {:region => region.region_name}

          # Collect, parse and save entity data
          parser, count, total_parts, sweep_scope = save_entity(entity_type, refresh_state_uuid, parser, scope, count, total_parts, sweep_scope)

          # Collect, parse and save related entities data, if there are any
          (related_entities[entity_type.to_sym] || []).each do |related_entity_type|
            parser, count, total_parts, sweep_scope = save_entity(related_entity_type, refresh_state_uuid, parser, scope, count, total_parts, sweep_scope)
          end
        end

        if count > 0
          # Save the rest
          refresh_state_part_uuid = SecureRandom.uuid
          total_parts             += save_inventory(parser.collections.values, inventory_name, schema_name, refresh_state_uuid, refresh_state_part_uuid)
          sweep_scope.merge(parser.collections.values.map(&:name))
        end

        logger.info("Collecting #{entity_type} with :refresh_state_uuid => '#{refresh_state_uuid}'...Complete - Parts [#{total_parts}]")

        sweep_scope = sweep_scope.to_a
        logger.info("Sweeping inactive records for #{sweep_scope} with :refresh_state_uuid => '#{refresh_state_uuid}'...")

        sweep_inventory(inventory_name, schema_name, refresh_state_uuid, total_parts, sweep_scope)

        logger.info("Sweeping inactive records for #{sweep_scope} with :refresh_state_uuid => '#{refresh_state_uuid}'...Complete")
      end

      # Collect, parse and save entity data
      def save_entity(entity_type, refresh_state_uuid, parser, scope, count, total_parts, sweep_scope)
        send(entity_type.to_s, scope).each do |entity|
          count += 1
          parser.send("parse_#{entity_type}", entity, scope)

          if count >= limits[entity_type]
            count                   = 0
            refresh_state_part_uuid = SecureRandom.uuid
            total_parts             += save_inventory(parser.collections.values, inventory_name, schema_name, refresh_state_uuid, refresh_state_part_uuid)
            sweep_scope.merge(parser.collections.values.map(&:name))

            parser = create_parser
          end
        end

        return parser, count, total_parts, sweep_scope
      end

      # Entities that should be always refreshed and sweeped together, e.g. if by scanning Vms, we're also creating
      # network adapters
      def related_entities
        {
          :vms => [:network_adapters, :floating_ips]
        }
      end

      def create_parser
        Parser.new
      end

      def cloud_formations_entity_types
        %w(orchestrations_stacks)
      end

      def ec2_entity_types
        %w(source_regions vms volumes networks subnets security_groups)
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
        Connection.service_catalog(connection_attributes.merge(scope))
      end

      def ec2_connection(scope)
        Connection.ec2(connection_attributes.merge(scope))
      end

      def pricing_connection(scope)
        Connection.pricing(connection_attributes.merge(scope))
      end

      def cloud_formation_connection(scope)
        Connection.cloud_formation(connection_attributes.merge(scope))
      end

      def ingress_api_client
        TopologicalInventoryIngressApiClient::DefaultApi.new
      end

      def default_region
        "us-east-1"
      end

      def inventory_name
        "Amazon"
      end
    end
  end
end
