module Amazon
  class Parser
    module Vm
      def parse_vms(instance, _scope)
        uid    = instance.id
        name   = get_from_tags(instance.tags, :name) || uid
        flavor = lazy_find(:flavors, :source_ref => instance.instance_type) if instance.instance_type

        vm = TopologicalInventoryIngressApiClient::Vm.new(
          :source_ref    => uid,
          :uid_ems       => uid,
          :name          => name,
          :power_state   => parse_vm_power_state(instance.state),
          :flavor        => flavor,
          :mac_addresses => parse_network(instance)[:mac_addresses],
        )

        collections[:vms].data << vm
        parse_vm_tags(uid, instance.tags)

        uid(vm)
      end

      private

      def parse_network(instance)
        network = {
          :fqdn                 => instance.public_dns_name,
          :private_ip_address   => instance.private_ip_address,
          :public_ip_address    => instance.public_ip_address,
          :mac_addresses        => [],
          :private_ip_addresses => [],
          :public_ip_addresses  => [],
        }

        (instance.network_interfaces || []).each do |interface|
          network[:mac_addresses] << interface.mac_address
          interface.private_ip_addresses.each do |private_ip|
            network[:private_ip_addresses] << private_ip.private_ip_address
            network[:public_ip_addresses] << private_ip&.association&.public_ip if private_ip&.association&.public_ip
          end
        end

        network
      end

      def parse_vm_tags(vm_uid, tags)
        tags.each do |tag|
          collections[:vm_tags].data << TopologicalInventoryIngressApiClient::VmTag.new(
            :vm    => lazy_find(:vms, :source_ref => vm_uid),
            :tag   => lazy_find(:tags, :name => tag.key),
            :value => tag.value,
          )
        end
      end

      def parse_vm_power_state(state)
        case state&.name
        when "pending"
          "suspended"
        when "running"
          "on"
        when "shutting-down", "stopping", "shutting_down"
          "powering_down"
        when "terminated"
          "terminated"
        when "stopped"
          "off"
        else
          "unknown"
        end
      end
    end
  end
end
