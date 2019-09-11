module TopologicalInventory
  module Amazon
    class Collector
      module Organizations
        def subscriptions(scope)
          # Get cached result
          return @subscriptions_cache if @subscriptions_cache

          # We want to collect this for only default region, since all regions return the same result
          return [] unless scope[:region] == default_region && scope[:master]

          # Get all accounts inside AWS organization
          @subscriptions_cache = []

          # If we were able to load master account and we have role defined for sub account access, we can load
          # a list of subaccounts
          if sub_account_role
            begin
              master_account_id = organizations_connection(:region => default_region).client.describe_organization&.organization&.master_account_id
            rescue Aws::Organizations::Errors::AccessDeniedException => e
              logger.warn("Can't access describe_organization API, [#{e.class}, #{e.message}]")
            end
            if master_account_id
              begin
                paginated_query({:region => default_region}, :organizations_connection,
                                :accounts, :listing_keyword => "list").each do |account|
                  @subscriptions_cache << {
                    :account_id   => account.id,
                    :master       => account.id == master_account_id,
                    :account_name => account.name
                  }
                end
              rescue Aws::Organizations::Errors::AccessDeniedException => e
                logger.warn("Can't access list_organizations API, [#{e.class}, #{e.message}]")
              end
            end
          end

          # If we are not able to scan organization just add current creds as a master account
          if @subscriptions_cache.empty?
            # TODO(lsmola): try to fetch account number from other API
            @subscriptions_cache << {
              :account_id   => nil,
              :master       => true,
              :account_name => nil
            }
          end

          @subscriptions_cache
        end
      end
    end
  end
end
