module Amazon
  class Parser
    module Flavor
      def parse_flavors(hash, _scope)
        attributes = hash.dig("product", "attributes") || {}
        return unless attributes["instanceType"]

        storage_size, storage_count = parse_flavor_storage(attributes["storage"])

        service_instance = TopologicalInventoryIngressApiClient::Flavor.new(
          :source_ref => attributes["instanceType"],
          :name       => attributes["instanceType"],
          :cpus       => parse_vcpu(attributes["vcpu"]),
          :disk_size  => storage_size,
          :disk_count => storage_count,
          :memory     => parse_flavor_memory(attributes["memory"]),
          :extra      => {
            :attributes => {
              :dedicatedEbsThroughput => attributes["dedicatedEbsThroughput"],
              :physicalProcessor      => attributes["physicalProcessor"],
              :clockSpeed             => attributes["clockSpeed"],
              :ecu                    => attributes["ecu"],
              :networkPerformance     => attributes["networkPerformance"],
              :processorFeatures      => attributes["processorFeatures"],
            },
            :prices     => {
              :OnDemand => hash.dig("terms", "OnDemand"),
            }
          }
        )

        collections[:flavors].data << service_instance

        uid(service_instance)
      end

      private

      def parse_flavor_storage(storage)
        match = /^(\d+)\sx\s(\d+).*$/.match(storage&.gsub(",", ""))
        if match
          storage_size = (match[2].to_f * 1024**3).to_i # convert GiB to B
          return storage_size, match[1]
        else
          return 0, 0 # EBS only flavor
        end
      end

      def parse_flavor_memory(memory)
        match = /^((\d*[.])?(\d+)).*$/.match(memory&.gsub(",", ""))
        return 0 unless match

        (match[1].to_f * 1024**3).to_i # convert GiB to B
      end

      def parse_vcpu(vcpu)
        vcpu.to_i
      end
    end
  end
end
