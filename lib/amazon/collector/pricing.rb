module Amazon
  class Collector
    module Pricing
      def flavors(scope)
        # TODO(lsmola) should we have flavor per region?
        return [] unless scope[:region] == "us-east-1"

        func = lambda do |&blk|
          result = flavors_query(scope)
          while 1
            result.price_list.each do |flavor|
              parsed_flavor = JSON.parse(flavor)
              blk.call(parsed_flavor, scope)
            end

            break unless result.next_token

            result = flavors_query(scope, :next_token => result.next_token)
          end
        end
        Amazon::Iterator.new(func, "Couldn't fetch 'flavors' from Aws::Pricing.")
      end

      def flavors_query(scope, next_token: nil)
        params              = {
          :service_code => "AmazonEC2",
          :filters      => [
            {:field => "productFamily", :type => "TERM_MATCH", :value => "Compute Instance"},
            {:field => "operatingSystem", :type => "TERM_MATCH", :value => "Linux"},
            {:field => "location", :type => "TERM_MATCH", :value => "US East (N. Virginia)"},
            {:field => "tenancy", :type => "TERM_MATCH", :value => "Shared"},
            {:field => "operation", :type => "TERM_MATCH", :value => "RunInstances"},
            {:field => "capacitystatus", :type => "TERM_MATCH", :value => "Used"},
          ]
        }
        params[:next_token] = next_token if next_token

        pricing_connection(scope).client.get_products(params)
      end
    end
  end
end
