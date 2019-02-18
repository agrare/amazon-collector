#
# Uses the AWS Config or CloudWatch service to monitor for events.
#
# AWS Config or CloudWatch events are collected in an SNS Topic.  Each appliance uses a unique
# SQS queue subscribed to the AWS Config topic.  If the appliance-specific queue
# doesn't exist, this event monitor will create the queue and subscribe the
# queue to the AWS Config topic.

#
class Amazon::EventCatcherStream
  class ProviderUnreachable < StandardError
  end

  #
  # Creates an event monitor
  #
  # @param [Amazon::EventCatcher] event_catcher

  def initialize(event_catcher)
    @event_catcher = event_catcher
  end

  #
  # Collect events off the appliance-specific queue and return the events as a
  # batch to the caller.
  #
  # :yield: array of Amazon events as hashes
  #
  def poll
    event_catcher.sqs_connection do |sqs|
      queue_poller = Aws::SQS::QueuePoller.new(
        find_or_create_queue,
        :client                 => sqs.client,
        :wait_time_seconds      => 20,
        # :max_number_of_messages => 10
      )
      begin
        queue_poller.poll do |sqs_message|
          yield sqs_message if sqs_message
        end
      rescue Aws::SQS::Errors::ServiceError => exception
        raise ProviderUnreachable, exception.message
      end
    end
  end

  private

  attr_reader :event_catcher

  # @return [String] is a queue_url
  def find_or_create_queue
    queue_url = sqs_get_queue_url(queue_name)
    subscribe_topic_to_queue(sns_topic, queue_url) unless queue_subscribed_to_topic?(queue_url, sns_topic)
    add_policy_to_queue(queue_url, sns_topic.arn) unless queue_has_policy?(queue_url, sns_topic.arn)
    queue_url
  rescue Aws::SQS::Errors::NonExistentQueue
    # $aws_log.info("#{log_header} Amazon SQS Queue #{queue_name} does not exist; creating queue")
    queue_url = sqs_create_queue(queue_name)
    subscribe_topic_to_queue(sns_topic, queue_url)
    add_policy_to_queue(queue_url, sns_topic.arn)
    # $aws_log.info("#{log_header} Created Amazon SQS Queue #{queue_name} and subscribed to AWSConfig_topic")
    queue_url
  rescue Aws::SQS::Errors::ServiceError => exception
    raise ProviderUnreachable, exception.message
  end

  def queue_has_policy?(queue_url, topic_arn)
    policy_attribute = 'Policy'
    policy = event_catcher.sqs_connection do |sqs|
      sqs.client.get_queue_attributes(
        :queue_url       => queue_url,
        :attribute_names => [policy_attribute]
      ).attributes[policy_attribute]
    end

    policy == queue_policy(queue_url_to_arn(queue_url), topic_arn)
  end

  def queue_subscribed_to_topic?(queue_url, topic)
    queue_arn = queue_url_to_arn(queue_url)
    topic.subscriptions.any? { |subscription| subscription.attributes['Endpoint'] == queue_arn }
  end

  def sqs_create_queue(queue_name)
    event_catcher.sqs_connection do |sqs|
      sqs.client.create_queue(:queue_name => queue_name).queue_url
    end
  end

  def sqs_get_queue_url(queue_name)
    # $aws_log.debug("#{log_header} Looking for Amazon SQS Queue #{queue_name} ...")
    event_catcher.sqs_connection do |sqs|
      sqs.client.get_queue_url(:queue_name => queue_name).queue_url
    end
  end

  # @return [Aws::SNS::Topic] the found topic
  # @raise [ProviderUnreachable] in case the topic is not found
  def sns_topic
    event_catcher.sns_connection do |sns|
      get_topic(sns) || create_topic(sns)
    end
  end

  def get_topic(sns)
    sns.topics.detect { |t| t.arn.split(/:/)[-1] == event_catcher.sns_topic }
  end

  def create_topic(sns)
    topic = sns.create_topic(:name => event_catcher.sns_topic)
    # $aws_log.info("Created SNS topic #{event_catcher.sns_topic}")
    topic
  rescue Aws::SNS::Errors::ServiceError => err
    raise ProviderUnreachable, "Cannot create SNS topic #{event_catcher.sns_topic}, #{err.class.name}, Message=#{err.message}"
  end

  # @param [Aws::SNS::Topic] topic
  def subscribe_topic_to_queue(topic, queue_url)
    queue_arn = queue_url_to_arn(queue_url)
    # $aws_log.info("#{log_header} Subscribing Queue #{queue_url} to #{topic.arn}")
    subscription = topic.subscribe(:protocol => 'sqs', :endpoint => queue_arn)
    raise ProviderUnreachable, "Can't subscribe to #{queue_arn}" if subscription.arn.nil? || subscription.arn.empty?
  end

  def add_policy_to_queue(queue_url, topic_arn)
    queue_arn = queue_url_to_arn(queue_url)
    policy    = queue_policy(queue_arn, topic_arn)

    event_catcher.sqs_connection do |sqs|
      sqs.client.set_queue_attributes(
        :queue_url  => queue_url,
        :attributes => {'Policy' => policy}
      )
    end
  end

  def queue_url_to_arn(queue_url)
    @queue_url_to_arn ||= {}
    @queue_url_to_arn[queue_url] ||= begin
      arn_attribute = "QueueArn"
      event_catcher.sqs_connection do |sqs|
        sqs.client.get_queue_attributes(
          :queue_url       => queue_url,
          :attribute_names => [arn_attribute]
        ).attributes[arn_attribute]
      end
    end
  end

  def log_header
    @log_header ||= "(#{self.class.name}#)"
  end

  def queue_name
    # Generating the same queue name for source, so we can scale the event catcher
    @queue_name ||= "topological-inventory-awsconfig-queue_#{event_catcher.source}"
  end

  def queue_policy(queue_arn, topic_arn)
    <<EOT
{
  "Version": "2012-10-17",
  "Id": "#{queue_arn}/SQSDefaultPolicy",
  "Statement": [
    {
      "Sid": "#{Digest::MD5.hexdigest(queue_arn)}",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "SQS:SendMessage",
      "Resource": "#{queue_arn}",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "#{topic_arn}"
        }
      }
    }
  ]
}
EOT
  end
end
