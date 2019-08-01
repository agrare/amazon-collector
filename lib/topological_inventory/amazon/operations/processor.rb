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
        end

        def process
          # TODO: handle the operation
        end

        private

        attr_accessor :message
      end
    end
  end
end
