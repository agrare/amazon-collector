require "active_support/inflector"
require "amazon/parser/service_offering"
require "amazon/parser/service_plan"
require "amazon/parser/service_instance"

module Amazon
  class Parser
    include Amazon::Parser::ServiceOffering
    include Amazon::Parser::ServicePlan
    include Amazon::Parser::ServiceInstance

    attr_accessor :connection, :collections, :resource_timestamp

    def initialize(connection = nil)
      entity_types = [:service_instances, :service_offerings, :service_plans]

      self.connection         = connection
      self.resource_timestamp = Time.now.utc
      self.collections        = entity_types.each_with_object({}).each do |entity_type, collections|
        collections[entity_type] = TopologicalInventory::IngressApi::Client::InventoryCollection.new(:name => entity_type)
      end
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

    def archive_entity(inventory_object, entity)
      source_deleted_at                  = entity.metadata&.deletionTimestamp || Time.now.utc
      inventory_object.source_deleted_at = source_deleted_at
    end

    def lazy_find(collection, reference, ref: :manager_ref)
      TopologicalInventory::IngressApi::Client::InventoryObjectLazy.new(
        :inventory_collection_name => collection,
        :reference                 => reference,
        :ref                       => ref,
      )
    end

    def lazy_find_namespace(name)
      return if name.nil?

      TopologicalInventory::IngressApi::Client::InventoryObjectLazy.new(
        :inventory_collection_name => :container_projects,
        :reference                 => {:name => name},
        :ref                       => :by_name,
      )
    end

    def lazy_find_node(name)
      return if name.nil?

      TopologicalInventory::IngressApi::Client::InventoryObjectLazy.new(
        :inventory_collection_name => :container_nodes,
        :reference                 => {:name => name},
        :ref                       => :by_name,
      )
    end

    def uid(entity)
      {
        :source_ref => entity.source_ref
      }
    end
  end
end
