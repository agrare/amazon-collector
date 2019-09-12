module TopologicalInventory
  module Amazon
    class Collector
      module Ec2
        def source_regions(scope)
          # We want to collect this for only default region, since all regions return the same result
          return [] unless scope[:region] == default_region && scope[:master]

          paginated_query(scope, :ec2_connection, :regions)
        end

        def vms(scope)
          ec2_connection(scope).instances
        end

        def availability_zones(scope)
          paginated_query(scope, :ec2_connection, :availability_zones)
        end

        def key_pairs(scope)
          paginated_query(scope, :ec2_connection, :key_pairs)
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
          paginated_query(scope, :ec2_connection, :volumes)
        end

        def networks(scope)
          paginated_query(scope, :ec2_connection, :vpcs)
        end

        def subnets(scope)
          paginated_query(scope, :ec2_connection, :subnets)
        end

        def security_groups(scope)
          paginated_query(scope, :ec2_connection, :security_groups)
        end

        def network_adapters(scope)
          paginated_query(scope, :ec2_connection, :network_interfaces)
        end

        def floating_ips(scope)
          paginated_query(scope, :ec2_connection, :addresses)
        end
      end
    end
  end
end
