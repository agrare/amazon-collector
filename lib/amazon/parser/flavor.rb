module Amazon
  class Parser
    module Flavor
      def parse_flavors(hash, _scope)
        attributes                  = hash["product"]["attributes"]
        storage_size, storage_count = parse_flavor_storage(attributes["storage"])

        service_instance = TopologicalInventory::IngressApi::Client::Flavor.new(
          :source_ref => attributes["instanceType"],
          :name       => attributes["instanceType"],
          :cpus       => parse_vcpu(attributes["vcpu"]),
          :disk_size  => storage_size,
          :disk_count => storage_count,
          :memory     => parse_flavor_memory(attributes["memory"]),
          :extra      => {
            :attributes => {
              :memory                 => attributes["memory"],
              :dedicatedEbsThroughput => attributes["dedicatedEbsThroughput"],
              :vcpu                   => attributes["vcpu"],
              :storage                => attributes["storage"],
              :physicalProcessor      => attributes["physicalProcessor"],
              :clockSpeed             => attributes["clockSpeed"],
              :ecu                    => attributes["ecu"],
              :networkPerformance     => attributes["networkPerformance"],
              :processorFeatures      => attributes["processorFeatures"],
            },
            :prices     => {
              :OnDemand => hash["terms"]["OnDemand"],
            }
          }
        )

        collections[:flavors].data << service_instance

        uid(service_instance)
      end

      private

      def parse_flavor_storage(storage)
        match = /^(\d+)\sx\s(\d+).*$/.match(storage.gsub(",", ""))
        if match
          return match[2], match[1]
        else
          return 0, 0 # EBS only flavor
        end
      end

      def parse_flavor_memory(memory)
        match = /^((\d*[.])?(\d+)).*$/.match(memory.gsub(",", ""))
        match[1].to_f * 1024 ** 3 # convert GiB to B
      end

      def parse_vcpu(vcpu)
        vcpu.to_i
      end
    end
  end
end
