module Amazon
  class Parser
    module Vm
      def parse_vms(instance, _scope)
        uid  = instance.id
        name = get_from_tags(instance.tags, :name) || uid

        vm = TopologicalInventory::IngressApi::Client::Vm.new(
          :source_ref  => uid,
          :uid_ems     => uid,
          :name        => name,
          :power_state => parse_vm_power_state(instance.state)
        )

        collections[:vms].data << vm

        uid(vm)
      end

      private

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
