require "active_support/inflector"
require "amazon/parser/source_region"
require "amazon/parser/service_offering"
require "amazon/parser/service_plan"
require "amazon/parser/service_instance"
require "amazon/parser/flavor"
require "amazon/parser/vm"
require "amazon/parser/volume"
require "amazon/parser/volume_type"

module Amazon
  class Parser
    include Amazon::Parser::SourceRegion
    include Amazon::Parser::ServiceOffering
    include Amazon::Parser::ServicePlan
    include Amazon::Parser::ServiceInstance
    include Amazon::Parser::Flavor
    include Amazon::Parser::Vm
    include Amazon::Parser::Volume
    include Amazon::Parser::VolumeType

    attr_accessor :connection, :collections, :resource_timestamp

    def initialize(connection = nil)
      entity_types = [:source_regions, :service_instances, :service_offerings, :service_plans, :flavors, :vms, :vm_tags,
                      :volumes, :volume_attachments, :volume_types]

      self.connection         = connection
      self.resource_timestamp = Time.now.utc
      self.collections        = entity_types.each_with_object({}).each do |entity_type, collections|
        collections[entity_type] = TopologicalInventoryIngressApiClient::InventoryCollection.new(:name => entity_type, :data => [])
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
      TopologicalInventoryIngressApiClient::InventoryObjectLazy.new(
        :inventory_collection_name => collection,
        :reference                 => reference,
        :ref                       => ref,
      )
    end

    def uid(entity)
      {
        :source_ref => entity.source_ref
      }
    end

    def get_from_tags(tags, tag_name)
      tags.detect { |tag| tag.key.downcase == tag_name.to_s.downcase }&.value
    end
  end
end
