module Amazon
  class Collector
    module Ec2
      def source_regions(scope)
        return [] unless scope[:region] == "us-east-1"

        ec2_connection(scope).client.describe_regions.regions
      end

      def vms(scope)
        ec2_connection(scope).instances
      end

      def availability_zones(scope)
        ec2_connection(scope).client.describe_availability_zones[:availability_zones]
      end

      def key_pairs(scope)
        ec2_connection(scope).client.describe_key_pairs[:key_pairs]
      end

      def private_images(scope)
        ec2_connection(scope).client.describe_images(:owners  => [:self],
                                                     :filters => [{:name   => "image-type",
                                                                   :values => ["machine"]}]).images
      end

      def shared_images(scope)
        ec2_connection(scope).client.describe_images(:executable_users => [:self],
                                                     :filters          => [{:name   => "image-type",
                                                                            :values => ["machine"]}]).images
      end

      def public_images(scope)
        ec2_connection(scope).client.describe_images(:executable_users => [:all],
                                                     :filters          => options.to_hash[:public_images_filters]).images
      end

      def volumes(scope)
        ec2_connection(scope).client.describe_volumes[:volumes]
      end
    end
  end
end
