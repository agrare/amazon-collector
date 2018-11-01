module Amazon
  module Connection
    class << self
      def ec2(options)
        open(options.merge(:service => :EC2))
      end

      def cloud_formation(options)
        open(options.merge(:service => :CloudFormation))
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

      def open(options = {})
        access_key_id     = options[:access_key_id]
        secret_access_key = options[:secret_access_key]
        service           = options[:service]
        proxy             = options[:proxy_uri]
        region            = options[:region] || "us-east-1"

        raw_connect(access_key_id, secret_access_key, service, region, proxy)
      end

      private

      def raw_connect(access_key_id, secret_access_key, service, region, proxy_uri = nil, validate = false, uri = nil)
        require 'aws-sdk'
        # require 'patches/aws-sdk-core/seahorse_client_net_http_pool_patch'

        options            = {
          :access_key_id     => access_key_id,
          :secret_access_key => secret_access_key,
          :region            => region,
          :http_proxy        => proxy_uri,
          # :logger            => $aws_log,
          # :log_level         => :debug,
          # :log_formatter     => Aws::Log::Formatter.new(Aws::Log::Formatter.default.pattern.chomp)
        }

        options[:endpoint] = uri.to_s unless uri.nil?

        connection = Aws.const_get(service)::Resource.new(options)

        validate_connection(connection) if validate

        connection
      end

      def validate_connection(connection)
        connection_rescue_block do
          connection.client.describe_regions.regions.map(&:region_name)
        end
      end

      def connection_rescue_block
        yield
      rescue => err
        miq_exception = translate_exception(err)
        raise unless miq_exception

        log.error("Error Class=#{err.class.name}, Message=#{err.message}")
        raise miq_exception
      end

      def translate_exception(err)
        # require 'aws-sdk'
        # # require 'patches/aws-sdk-core/seahorse_client_net_http_pool_patch'
        # case err
        # when Aws::EC2::Errors::SignatureDoesNotMatch
        #   MiqException::MiqHostError.new "SignatureMismatch - check your AWS Secret Access Key and signing method"
        # when Aws::EC2::Errors::AuthFailure
        #   MiqException::MiqHostError.new "Login failed due to a bad username or password."
        # when Aws::Errors::MissingCredentialsError
        #   MiqException::MiqHostError.new "Missing credentials"
        # else
        #   MiqException::MiqHostError.new "Unexpected response returned from system: #{err.message}"
        # end
      end
    end
  end
end
