module Amazon
  class Parser
    module Flavor
      def parse_flavors(hash, scope)
        attributes = hash["product"]["attributes"]

        service_instance = TopologicalInventory::IngressApi::Client::Flavor.new(
          :source_ref        => attributes["instanceType"],
          :name              => attributes["instanceType"],
        )

        collections[:flavors].data << service_instance

        uid(service_instance)
      end
    end
  end
end
