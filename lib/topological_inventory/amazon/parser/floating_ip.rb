module TopologicalInventory::Amazon
  class Parser
    module FloatingIp
      def parse_floating_ips(ip, scope)
        stack_id        = get_from_tags(ip.tags, "aws:cloudformation:stack-id")
        stack           = lazy_find(:orchestration_stacks, :source_ref => stack_id) if stack_id
        network_adapter = lazy_find(:network_adapters, :source_ref => ip.network_interface_id) if ip.network_interface_id
        uid             = ip.allocation_id || ip.public_ip

        collections[:ipaddresses].data << TopologicalInventoryIngressApiClient::Ipaddress.new(
          :source_ref          => uid,
          :ipaddress           => ip.public_ip,
          :kind                => "elastic",
          :extra               => {
            :allocation_id      => ip.allocation_id,
            :association_id     => ip.association_id,
            :instance_id        => ip.instance_id,
            :domain             => ip.domain,
            :public_ipv_4_pool  => ip.public_ipv_4_pool,
            :private_ip_address => ip.private_ip_address,
          },
          :source_region       => lazy_find(:source_regions, :source_ref => scope[:region]),
          :subscription        => lazy_find_subscription(scope),
          :orchestration_stack => stack,
          :network_adapter     => network_adapter,
        )

        parse_tags(:ipaddresses, uid, ip.tags)
      end
    end
  end
end
