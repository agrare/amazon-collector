require "amazon/connection"
require "amazon/event_catcher_stream"
require "concurrent"
require "manageiq-messaging"

module Amazon
  class EventCatcher
    attr_reader :source, :sns_topic

    def initialize(source, region, access_key_id, secret_access_key, sns_topic, queue_host, queue_port, poll_time: 20)
      self.log               = Logger.new(STDOUT)
      self.secret_access_key = secret_access_key
      self.access_key_id     = access_key_id
      self.region            = region
      self.sns_topic         = sns_topic
      self.poll_time         = poll_time
      self.queue_host        = queue_host
      self.queue_port        = queue_port
      self.source            = source
    end

    def sqs_connection(scope = {})
      connection = Amazon::Connection.sqs(connection_attributes.merge(scope))
      if block_given?
        yield(connection)
      else
        connection
      end
    end

    def sns_connection(scope = {})
      connection = Amazon::Connection.sns(connection_attributes.merge(scope))
      if block_given?
        yield(connection)
      else
        connection
      end
    end

    def monitor_events!
      event_monitor_handle.poll do |event|
        publish_message(
          :source => source,
          :region => region,
          :data   => event.to_hash
        )
      end
    end

    private

    attr_accessor :log, :secret_access_key, :access_key_id, :region, :poll_time, :queue, :queue_host, :queue_port

    attr_writer :source, :sns_topic

    def event_monitor_handle
      @event_monitor_handle ||= begin
        Amazon::EventCatcherStream.new(self)
      end
    end

    def publish_message(message)
      messaging_client.publish_message(
        :service => "platform.topological-inventory.event-stream",
        :message => "event",
        :payload => message,
      )
    end

    def messaging_client
      ManageIQ::Messaging::Client.open(messaging_opts)
    end

    def messaging_opts
      {
        :protocol => :Kafka,
        :host     => queue_host,
        :port     => queue_port,
        :encoding => "json",
      }
    end

    def connection_attributes
      {:access_key_id => access_key_id, :secret_access_key => secret_access_key, :region => region}
    end
  end
end
