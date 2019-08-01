require "topological_inventory/amazon/logging"

module TopologicalInventory
  module Amazon
    module Operations
      class Processor
        include Logging

        def self.process!(message)
          new(message).process
        end

        def initialize(message)
          self.message = message
          self.model, self.method = message.message.split(".")

          self.params   = message.payload["params"]
          self.identity = message.payload["request_context"]
        end

        def process
          logger.info("Processing #{model}##{method} [#{params}]...")

          impl = Operations.const_get(model).new(params, identity) if Operations.const_defined?(model)
          unless impl
            logger.error("#{model}.#{method} is not implemented")
            return
          end

          result = impl.send(method)
          logger.info("Processing #{model}##{method} [#{params}]...Complete")
          result
        end

        private

        attr_accessor :message, :identity, :model, :method, :params
      end
    end
  end
end
