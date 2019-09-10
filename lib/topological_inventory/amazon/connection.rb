module TopologicalInventory
  module Amazon
    module Connection
      class << self
        def ec2(options)
          open(options.merge(:service => :EC2))
        end

        def cloud_formation(options)
          open(options.merge(:service => :CloudFormation))
        end

        def pricing(options)
          open(options.merge(:service => :Pricing))
        end

        def service_catalog(options)
          open(options.merge(:service => :ServiceCatalog))
        end

        def elb(options)
          open(options.merge(:service => :ElasticLoadBalancing))
        end

        def s3(options)
          open(options.merge(:service => :S3))
        end

        def sqs(options)
          open(options.merge(:service => :SQS))
        end

        def sns(options)
          open(options.merge(:service => :SNS))
        end

        def organizations(options)
          open(options.merge(:service => :Organizations))
        end

        def open(options = {})
          access_key_id        = options[:access_key_id]
          secret_access_key    = options[:secret_access_key]
          service              = options[:service]
          region               = options[:region]
          proxy_uri            = options[:proxy_uri]
          sub_account_role_arn = options[:sub_account_role_arn]

          raw_connect(access_key_id, secret_access_key, service, region, :proxy_uri => proxy_uri,
                      :sub_account_role_arn => sub_account_role_arn)
        end

        private

        def raw_connect(access_key_id, secret_access_key, service, region, proxy_uri: nil,
                        validate: false, uri: nil, sub_account_role_arn: nil)
          require "aws-sdk-ec2"
          require "aws-sdk-cloudformation"
          require "aws-sdk-pricing"
          require "aws-sdk-servicecatalog"
          require "aws-sdk-organizations"

          options = {
            :credentials => Aws::Credentials.new(access_key_id, secret_access_key),
            :region      => region,
            :http_proxy  => proxy_uri,
            # :logger            => $aws_log,
            # :log_level         => :debug,
            # :log_formatter     => Aws::Log::Formatter.new(Aws::Log::Formatter.default.pattern.chomp)
          }

          options[:endpoint] = uri.to_s unless uri.nil?

          if sub_account_role_arn
            options[:credentials] = Aws::AssumeRoleCredentials.new(
              :client            => Aws::STS::Client.new(options),
              :role_arn          => sub_account_role_arn,
              :role_session_name => "TopologicalInventory-#{service}"
            )
          end

          Aws.const_get(service)::Resource.new(options)
        end
      end
    end
  end
end
