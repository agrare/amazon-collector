module TopologicalInventory::Amazon
  class Parser
    module Subnet
      def parse_subnets(subnet, scope)
        stack_id = get_from_tags(subnet.tags, "aws:cloudformation:stack-id")
        stack    = lazy_find(:orchestration_stacks, :source_ref => stack_id) if stack_id
        network  = lazy_find(:cloud_networks, :source_ref => subnet.vpc_id) if subnet.vpc_id

        collections[:subnets].data << TopologicalInventoryIngressApiClient::Subnet.new(
          :source_ref          => subnet.subnet_id,
          :name                => get_from_tags(subnet.tags, 'name') || subnet.subnet_id,
          :cidr                => subnet.cidr_block,
          :status              => subnet.state.try(:to_s),
          :extra               => {
            :subnet_arn                       => subnet.subnet_arn,
            :availability_zone                => subnet.availability_zone,
            :available_ip_address_count       => subnet.available_ip_address_count,
            :default_for_az                   => subnet.default_for_az,
            :map_public_ip_on_launch          => subnet.map_public_ip_on_launch,
            :assign_ipv_6_address_on_creation => subnet.assign_ipv_6_address_on_creation,
            :ipv_6_cidr_block_association_set => (subnet.ipv_6_cidr_block_association_set || []).map(&:to_h)

          },
          :cloud_network       => network,
          :source_region       => lazy_find(:source_regions, :source_ref => scope[:region]),
          :orchestration_stack => stack
        )

        parse_subnet_tags(subnet.subnet_id, subnet.tags)
      end

      def parse_subnet_tags(subnet_uid, tags)
        tags.each do |tag|
          collections[:subnet_tags].data << TopologicalInventoryIngressApiClient::SubnetTag.new(
            :subnet => lazy_find(:subnets, :source_ref => subnet_uid),
            :tag    => lazy_find(:tags, :name => tag.key, :value => tag.value, :namespace => "amazon"),
          )
        end
      end
    end
  end
end
