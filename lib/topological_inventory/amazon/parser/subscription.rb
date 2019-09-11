module TopologicalInventory::Amazon
  class Parser
    module Subscription
      def parse_subscriptions(account, _scope)
        return unless account[:account_id]

        collections[:subscriptions].data <<  TopologicalInventoryIngressApiClient::Subscription.new(
          :source_ref => account[:account_id],
          :name       => account[:account_name],
        )
      end
    end
  end
end
