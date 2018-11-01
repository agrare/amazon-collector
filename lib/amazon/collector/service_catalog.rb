module Amazon
  class Collector
    module ServiceCatalog
      def service_offerings
        service_catalog_connection.client.search_products_as_admin.product_view_details
      rescue => e
        log.error("Couldn't fetch 'search_products_as_admin' of service catalog, message: #{e.message}")
        []
      end

      def service_instances
        func = lambda do |&blk|
            service_catalog_connection.client.scan_provisioned_products.provisioned_products.each do |service_instance|
              blk.call(:service_instance => service_instance, :described_record => describe_record(service_instance.last_record_id))
            end
          end
        Amazon::Iterator.new(func,"Couldn't fetch 'provisioned_products' of service catalog.")
      end

      def service_plans
        func = lambda do |&blk|
          service_offerings.each do |service_offering|
            # TODO(lsmola) too many API calls, we need to do it in multiple threads
            product_id = service_offering.product_view_summary.product_id

            # Taking provisioning_artifacts of described product returns only active artifacts, doing list_provisioning_artifacts
            # we are not able to recognize the active ones. Same with describe_product_as_admin, status is missing. Status is
            # in the describe_provisioning_artifact, but it is wrong (always ACTIVE)
            artifacts    = describe_product(product_id)
            launch_paths = list_launch_paths(product_id)

            launch_paths.each do |launch_path|
              artifacts.each do |artifact|
                plan                           = {
                  :artifact         => artifact,
                  :launch_path      => launch_path,
                  :service_offering => service_offering
                }
                plan[:provisioning_parameters] = describe_provisioning_parameters(product_id, artifact.id, launch_path.id)
                blk.call(plan)
              end
            end
          end
        end

        Amazon::Iterator.new(func, "Couldn't fetch 'describe_provisioning_parameters' of service catalog.")
      end

      private

      def describe_provisioning_parameters(product_id, artifact_id, launch_path_id)
        service_catalog_connection.client.describe_provisioning_parameters(
          :product_id               => product_id,
          :provisioning_artifact_id => artifact_id,
          :path_id                  => launch_path_id
        )
      rescue => e
        ident = {:product_id => product_id, :artifact_id => artifact_id, :launch_path_id => launch_path_id}
        log.warn("Couldn't fetch 'describe_provisioning_parameters' of service catalog for #{ident}, message: #{e.message}")
        nil
      end

      def describe_product(product_id)
        service_catalog_connection.client.describe_product(:id => product_id).provisioning_artifacts
      rescue => e
        log.warn("Couldn't fetch 'describe_product' of service catalog, message: #{e.message}")
        []
      end

      def list_launch_paths(product_id)
        service_catalog_connection.client.list_launch_paths(:product_id => product_id).launch_path_summaries
      rescue => e
        log.warn("Couldn't fetch 'list_launch_paths' of service catalog, message: #{e.message}")
        []
      end

      def describe_record(record_id)
        service_catalog_connection.client.describe_record(:id => record_id)
      rescue => e
        log.warn("Couldn't fetch 'describe_record' of service catalog, message: #{e.message}")
        nil
      end
    end
  end
end
