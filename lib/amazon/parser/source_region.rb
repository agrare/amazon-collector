module Amazon
  class Parser
    module SourceRegion
      def parse_source_regions(region, _scope)
        region = TopologicalInventory::IngressApi::Client::SourceRegion.new(
          :source_ref => region.region_name,
          :name       => region.region_name,
          :endpoint   => region.endpoint,
        )

        collections[:source_regions].data << region

        uid(region)
      end
    end
  end
end
