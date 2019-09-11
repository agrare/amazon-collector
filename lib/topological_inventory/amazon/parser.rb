require "active_support/inflector"
require "topological_inventory/amazon/parser/source_region"
require "topological_inventory/amazon/parser/service_offering"
require "topological_inventory/amazon/parser/service_plan"
require "topological_inventory/amazon/parser/service_instance"
require "topological_inventory/amazon/parser/flavor"
require "topological_inventory/amazon/parser/floating_ip"
require "topological_inventory/amazon/parser/network"
require "topological_inventory/amazon/parser/network_adapter"
require "topological_inventory/amazon/parser/security_group"
require "topological_inventory/amazon/parser/subnet"
require "topological_inventory/amazon/parser/vm"
require "topological_inventory/amazon/parser/volume"
require "topological_inventory/amazon/parser/volume_type"
require "topological_inventory-ingress_api-client"
require "topological_inventory-ingress_api-client/collector.rb"
require "topological_inventory-ingress_api-client/collector/inventory_collection_storage.rb"

module TopologicalInventory
  module Amazon
    class Parser
      include Parser::SourceRegion
      include Parser::ServiceOffering
      include Parser::ServicePlan
      include Parser::ServiceInstance
      include Parser::Flavor
      include Parser::FloatingIp
      include Parser::Network
      include Parser::NetworkAdapter
      include Parser::SecurityGroup
      include Parser::Subnet
      include Parser::Vm
      include Parser::Volume
      include Parser::VolumeType

      attr_accessor :connection, :collections, :resource_timestamp

      def initialize(connection = nil)
        self.connection         = connection
        self.resource_timestamp = Time.now.utc
        self.collections = TopologicalInventoryIngressApiClient::Collector::InventoryCollectionStorage.new
      end

      private

      def parse_base_item(entity)
        {
          :name               => entity.metadata.name,
          :resource_version   => entity.metadata.resourceVersion,
          :resource_timestamp => resource_timestamp,
          :source_created_at  => entity.metadata.creationTimestamp,
          :source_ref         => entity.metadata.uid,
        }
      end

      def parse_tags(collection, uid, tags)
        client_class = "TopologicalInventoryIngressApiClient::#{collection.to_s.singularize.camelize}Tag".constantize

        (tags || []).each do |tag|
          collections["#{collection.to_s.singularize}_tags".to_sym].data << client_class.new(
            collection.to_s.singularize.to_sym => lazy_find(collection, :source_ref => uid),
            :tag                               => lazy_find(:tags, :name => tag.key, :value => tag.value, :namespace => "amazon"),
          )
        end
      end

      def archive_entity(inventory_object, entity)
        source_deleted_at                  = entity.metadata&.deletionTimestamp || Time.now.utc
        inventory_object.source_deleted_at = source_deleted_at
      end

      def lazy_find(collection, reference, ref: :manager_ref)
        TopologicalInventoryIngressApiClient::InventoryObjectLazy.new(
          :inventory_collection_name => collection,
          :reference                 => reference,
          :ref                       => ref,
        )
      end

      def lazy_find_subscription(scope)
        if scope[:account_id]
          lazy_find(:subscriptions, :source_ref => scope[:account_id])
        end
      end

      def get_from_tags(tags, tag_name)
        (tags || []).detect { |tag| tag.key.downcase == tag_name.to_s.downcase }&.value
      end
    end
  end
end
