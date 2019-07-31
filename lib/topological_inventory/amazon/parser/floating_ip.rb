module TopologicalInventory::Amazon
  class Parser
    module FloatingIp
      def parse_floating_ips(ip, scope)
        stack_id        = get_from_tags(ip.tags, "aws:cloudformation:stack-id")
        stack           = lazy_find(:orchestration_stacks, :source_ref => stack_id) if stack_id
        network_adapter = lazy_find(:network_adapters, :source_ref => ip.network_interface_id) if ip.network_interface_id

        collections[:floating_ips].data << TopologicalInventoryIngressApiClient::FloatingIp.new(
          :source_ref          => ip.allocation_id || ip.public_ip,
          :ipaddress           => ip.public_ip,
          :extra               => {
            :allocation_id      => ip.allocation_id,
            :association_id     => ip.association_id,
            :instance_id        => ip.instance_id,
            :domain             => ip.domain,
            :public_ipv_4_pool  => ip.public_ipv_4_pool,
            :private_ip_address => ip.private_ip_address,
          },
          :source_region       => lazy_find(:source_regions, :source_ref => scope[:region]),
          :orchestration_stack => stack,
          :network_adapter     => network_adapter,
        )

        parse_floating_ip_tags(ip.public_ip, ip.tags)
      end

      def parse_floating_ip_tags(floating_ip_uid, tags)
        tags.each do |tag|
          collections[:floating_ip_tags].data << TopologicalInventoryIngressApiClient::NetworkTag.new(
            :floating_ip => lazy_find(:floating_ips, :source_ref => floating_ip_uid),
            :tag         => lazy_find(:tags, :name => tag.key, :value => tag.value, :namespace => "amazon"),
          )
        end
      end
    end
  end
end
