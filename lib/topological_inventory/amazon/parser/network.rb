module TopologicalInventory::Amazon
  class Parser
    module Network
      def parse_networks(vpc, scope)
        stack_id = get_from_tags(vpc.tags, "aws:cloudformation:stack-id")
        stack    = lazy_find(:orchestration_stacks, :source_ref => stack_id) if stack_id

        collections[:networks].data << TopologicalInventoryIngressApiClient::Network.new(
          :source_ref          => vpc.vpc_id,
          :name                => get_from_tags(vpc.tags, 'name') || vpc.vpc_id,
          :cidr                => vpc.cidr_block,
          :status              => vpc.state == "available" ? "active" : "inactive",
          :extra               => {
            :ipv_6_cidr_block_association_set => vpc.ipv_6_cidr_block_association_set.map(&:to_h),
            :cidr_block_association_set       => vpc.cidr_block_association_set.map(&:to_h),
            :dhcp_options_id                  => vpc.dhcp_options_id,
            :is_default                       => vpc.is_default,
            :instance_tenancy                 => vpc.instance_tenancy,

          },
          :source_region       => lazy_find(:source_regions, :source_ref => scope[:region]),
          :orchestration_stack => stack
        )

        parse_tags(:networks, vpc.vpc_id, vpc.tags)
      end
    end
  end
end
