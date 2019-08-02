module TopologicalInventory::Amazon
  class Parser
    module NetworkAdapter
      def parse_network_adapters(interface, scope)
        stack_id = get_from_tags(interface.tag_set, "aws:cloudformation:stack-id")
        stack    = lazy_find(:orchestration_stacks, :source_ref => stack_id) if stack_id

        instance_id = interface.attachment&.instance_id
        device      = lazy_find(:vms, :source_ref => instance_id) if instance_id

        collections[:network_adapters].data << TopologicalInventoryIngressApiClient::NetworkAdapter.new(
          :source_ref          => interface.network_interface_id,
          :mac_address         => interface.mac_address,
          :extra               => {
            :association       => interface.association&.to_h,
            :attachment        => interface.attachment&.to_h,
            :ipv_6_addresses   => interface.ipv_6_addresses.map(&:to_h),
            :groups            => interface.groups.map(&:to_h),
            :availability_zone => interface.availability_zone,
            :description       => interface.description,
            :interface_type    => interface.interface_type,
            :private_dns_name  => interface.private_dns_name,
            :status            => interface.status,
            :requester_id      => interface.requester_id,
            :requester_managed => interface.requester_managed,
            :source_dest_check => interface.source_dest_check,
          },
          :source_region       => lazy_find(:source_regions, :source_ref => scope[:region]),
          :orchestration_stack => stack,
          :device              => device,
        )

        parse_network_adapter_ipaddresses(interface, scope)
        parse_network_adapter_public_ips(interface, scope)
        parse_network_adapter_tags(interface.network_interface_id, interface.tag_set)
      end

      def parse_network_adapter_ipaddresses(interface, scope)
        subnet = lazy_find(:subnets, :source_ref => interface.subnet_id) if interface.subnet_id

        interface.private_ip_addresses.each do |address|
          collections[:ipaddresses].data << TopologicalInventoryIngressApiClient::Ipaddress.new(
            :source_ref      => "#{interface.network_interface_id}___#{interface.subnet_id}___#{address.private_ip_address}",
            :ipaddress       => address.private_ip_address,
            :network_adapter => lazy_find(:network_adapters, :source_ref => interface.network_interface_id),
            :source_region   => lazy_find(:source_regions, :source_ref => scope[:region]),
            :subnet          => subnet,
            :kind            => "private",
            :extra           => {
              :primary          => address.primary,
              :private_dns_name => address.private_dns_name,
              :association      => address.association&.to_h
            }
          )
        end
      end

      def parse_network_adapter_tags(network_adapter_uid, tags)
        tags.each do |tag|
          collections[:network_adapter_tags].data << TopologicalInventoryIngressApiClient::NetworkTag.new(
            :network_adapter => lazy_find(:network_adapters, :source_ref => network_adapter_uid),
            :tag             => lazy_find(:tags, :name => tag.key, :value => tag.value, :namespace => "amazon"),
          )
        end
      end

      def parse_network_adapter_public_ips(interface, scope)
        interface.private_ip_addresses.each do |private_address|
          if private_address.association &&
            !(public_ip = private_address.association&.public_ip).blank? &&
            private_address.association&.allocation_id.blank?

            collections[:ipaddresses].data << TopologicalInventoryIngressApiClient::Ipaddress.new(
              :source_ref      => public_ip,
              :ipaddress       => public_ip,
              :network_adapter => lazy_find(:network_adapters, :source_ref => interface.network_interface_id),
              :source_region   => lazy_find(:source_regions, :source_ref => scope[:region]),
              :subnet          => nil,
              :kind            => "public",
              :extra           => {
                :private_ip_address => interface.private_ip_address,
              }
            )
          end
        end
      end
    end
  end
end
