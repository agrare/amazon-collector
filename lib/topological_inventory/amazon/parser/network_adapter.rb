module TopologicalInventory::Amazon
  class Parser
    module NetworkAdapter
      def parse_network_adapters(interface, scope)
        # require 'byebug'; byebug if interface.private_ip_addresses.detect { |x| x.association }
        stack_id = get_from_tags(interface.tag_set, "aws:cloudformation:stack-id")
        stack    = lazy_find(:orchestration_stacks, :source_ref => stack_id) if stack_id

        instance_id = interface.attachment&.instance_id
        device      = lazy_find(:vms, :source_ref => instance_id) if instance_id

        collections[:network_adapters].data << TopologicalInventoryIngressApiClient::NetworkAdapter.new(
          :source_ref          => interface.network_interface_id,
          :mac_address         => interface.mac_address,
          :extra               => {
            :association          => interface.association&.to_h,
            :attachment           => interface.attachment&.to_h,
            :private_ip_addresses => interface.private_ip_addresses.map(&:to_h),
            :ipv_6_addresses      => interface.ipv_6_addresses.map(&:to_h),
            :groups               => interface.groups.map(&:to_h),
            :availability_zone    => interface.availability_zone,
            :description          => interface.description,
            :interface_type       => interface.interface_type,
            :private_dns_name     => interface.private_dns_name,
            :status               => interface.status,
            :requester_id         => interface.requester_id,
            :requester_managed    => interface.requester_managed,
            :source_dest_check    => interface.source_dest_check,
          },
          :source_region       => lazy_find(:source_regions, :source_ref => scope[:region]),
          :orchestration_stack => stack,
          :device              => device,
        )

        parse_network_adapter_ipaddresses(interface)
        parse_network_adapter_tags(interface.network_interface_id, interface.tag_set)
      end

      def parse_network_adapter_ipaddresses(interface)
        subnet = lazy_find(:subnets, :source_ref => interface.subnet_id) if interface.subnet_id

        interface.private_ip_addresses.each do |address|
          collections[:ipaddresses].data << TopologicalInventoryIngressApiClient::Ipaddress.new(
            :ipaddress       => address.private_ip_address,
            :network_adapter => lazy_find(:network_adapters, :source_ref => interface.network_interface_id),
            :subnet          => subnet
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

      def parse_network_adapterssss(interface, scope)
        require 'byebug'; byebug

        uid             = network_port['network_interface_id']
        security_groups = network_port['groups'].blank? ? [] : network_port['groups'].map do |x|
          persister.security_groups.lazy_find(x['group_id'])
        end

        persister_network_port = persister.network_ports.find_or_build(uid).assign_attributes(
          :name            => uid,
          :status          => network_port['status'],
          :mac_address     => network_port['mac_address'],
          :device_owner    => network_port.fetch_path('attachment', 'instance_owner_id'),
          :device_ref      => network_port.fetch_path('attachment', 'instance_id'),
          :device          => persister.vms.lazy_find(network_port.fetch_path('attachment', 'instance_id')),
          :security_groups => security_groups,
        )

        network_port['private_ip_addresses'].each do |address|
          persister.cloud_subnet_network_ports.find_or_build_by(
            :address      => address['private_ip_address'],
            :cloud_subnet => persister.cloud_subnets.lazy_find(network_port['subnet_id']),
            :network_port => persister_network_port
          )
        end

        public_ips(network_port)
      end

      def public_ips(network_port)
        network_port['private_ip_addresses'].each do |private_address|
          if private_address['association'] &&
            !(public_ip = private_address.fetch_path('association', 'public_ip')).blank? &&
            private_address.fetch_path('association', 'allocation_id').blank?

            persister.floating_ips.find_or_build(public_ip).assign_attributes(
              :address            => public_ip,
              :fixed_ip_address   => private_address['private_ip_address'],
              :cloud_network_only => true,
              :network_port       => persister.network_ports.lazy_find(network_port['network_interface_id']),
              :vm                 => persister.network_ports.lazy_find(network_port['network_interface_id'],
                                                                       :key => :device)
            )
          end
        end
      end

      def ec2_floating_ips_and_ports
        collector.instances.each do |instance|
          next unless instance['network_interfaces'].blank?

          persister_network_port = persister.network_ports.find_or_build(instance['instance_id']).assign_attributes(
            :name            => get_from_tags(instance, 'name') || instance['instance_id'],
            :status          => nil,
            :mac_address     => nil,
            :device_owner    => nil,
            :device_ref      => nil,
            :device          => persister.vms.lazy_find(instance['instance_id']),
            :security_groups => instance['security_groups'].to_a.collect do |sg|
              persister.security_groups.lazy_find(sg['group_id'])
            end.compact,
          )

          persister.cloud_subnet_network_ports.find_or_build_by(
            :address      => instance['private_ip_address'],
            :cloud_subnet => nil,
            :network_port => persister_network_port
          )

          floating_ip_inferred_from_instance(persister_network_port, instance)
        end
      end

      def floating_ip_inferred_from_instance(persister_network_port, instance)
        uid = instance['public_ip_address']
        return nil if uid.blank?

        persister.floating_ips.find_or_build(uid).assign_attributes(
          :address            => uid,
          :fixed_ip_address   => instance['private_ip_address'],
          :cloud_network_only => false,
          :network_port       => persister_network_port,
          :vm                 => persister_network_port.device
        )
      end
    end
  end
end
