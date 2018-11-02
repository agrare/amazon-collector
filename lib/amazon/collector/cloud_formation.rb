module Amazon
  class Collector
    module CloudFormation
      def orchestration_stacks
        cloud_formation_connection.client.describe_stacks[:stacks]
      end

      private

      def orchestration_stack_resources(stack_name)
        cloud_formation_connection.client.list_stack_resources(:stack_name => stack_name).try(:stack_resource_summaries) || []
      rescue => e
        log.warn("Couldn't fetch 'list_stack_resources' from CloudFormation, message: #{e.message}")
        nil
      end

      def orchestration_stack_template(stack_name)
        cloud_formation_connection.client.get_template(:stack_name => stack_name).template_body
      rescue => e
        log.warn("Couldn't fetch 'get_template' from CloudFormation, message: #{e.message}")
        nil
      end
    end
  end
end
