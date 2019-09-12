module TopologicalInventory::Amazon
  class Parser
    module Reservation
      def parse_reservations(reservation, scope)
        uid    = reservation.reserved_instances_id
        flavor = lazy_find(:flavors, :source_ref => reservation.instance_type)

        collections[:reservations].data << TopologicalInventoryIngressApiClient::Reservation.new(
          :source_ref    => uid,
          :extra         => {
            :availability_zone   => reservation.availability_zone,
            :instance_count      => reservation.instance_count,
            :instance_type       => reservation.instance_type,
            :product_description => reservation.product_description,
            :state               => reservation.state,
            :usage_price         => reservation.usage_price,
            :currency_code       => reservation.currency_code,
            :instance_tenancy    => reservation.instance_tenancy,
            :offering_class      => reservation.offering_class,
            :offering_type       => reservation.offering_type,
            :recurring_charges   => reservation.recurring_charges.map(&:to_h),
            :scope               => reservation.scope,
          },
          :state         => reservation.state,
          :start         => reservation.start,
          :end           => reservation.end,
          :flavor        => flavor,
          :source_region => lazy_find(:source_regions, :source_ref => scope[:region]),
          :subscription  => lazy_find_subscription(scope),
        )

        parse_tags(:reservations, uid, reservation.tags)
      end
    end
  end
end
