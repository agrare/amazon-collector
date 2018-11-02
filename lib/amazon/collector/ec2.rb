module Amazon
  class Collector
    module Ec2
      def regions
        ec2_connection.client.describe_regions.regions
      end

      def instances
        ec2_connection.instances
      end

      def flavors
        ManageIQ::Providers::Amazon::InstanceTypes.all
      end

      def availability_zones
        ec2_connection.client.describe_availability_zones[:availability_zones]
      end

      def key_pairs
        ec2_connection.client.describe_key_pairs[:key_pairs]
      end

      def private_images
        ec2_connection.client.describe_images(:owners  => [:self],
                                              :filters => [{:name   => "image-type",
                                                            :values => ["machine"]}]).images
      end

      def shared_images
        ec2_connection.client.describe_images(:executable_users => [:self],
                                              :filters          => [{:name   => "image-type",
                                                                     :values => ["machine"]}]).images
      end

      def public_images
        ec2_connection.client.describe_images(:executable_users => [:all],
                                              :filters          => options.to_hash[:public_images_filters]).images
      end
    end
  end
end
