module Amazon
  class Parser
    module ServiceOffering
      def parse_service_offerings(service_offering)
        service_offering = TopologicalInventory::IngressApi::Client::ServiceOffering.new(
          :source_ref        => service_offering.product_view_summary.product_id,
          :name              => service_offering.product_view_summary.name,
          :description       => nil,
          :source_created_at => service_offering.created_time,
          :extra   => {
            :product_view_summary => service_offering.product_view_summary,
            :status               => service_offering.status,
            :product_arn          => service_offering.product_arn,
          }
        )

        collections[:service_offerings].data << service_offering

        uid(service_offering)
      end
    end
  end
end
