module TopologicalInventory::Amazon
  class Parser
    module SecurityGroup
      def parse_security_groups(sg, scope)
        stack_id = get_from_tags(sg.tags, "aws:cloudformation:stack-id")
        stack    = lazy_find(:orchestration_stacks, :source_ref => stack_id) if stack_id
        network  = lazy_find(:networks, :source_ref => sg.vpc_id) if sg.vpc_id

        collections[:security_groups].data << TopologicalInventoryIngressApiClient::SecurityGroup.new(
          :source_ref          => sg.group_id,
          :name                => sg.group_name || sg.group_id,
          :description         => sg.description,
          :extra               => {
            :ip_permissions        => sg.ip_permissions.map(&:to_h),
            :ip_permissions_egress => sg.ip_permissions_egress.map(&:to_h),
          },
          :source_region       => lazy_find(:source_regions, :source_ref => scope[:region]),
          :subscription        => lazy_find_subscription(scope),
          :orchestration_stack => stack,
          :network             => network,
        )

        parse_tags(:security_groups, sg.group_id, sg.tags)
      end
    end
  end
end
