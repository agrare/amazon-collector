require "topological_inventory/amazon/logging"

module TopologicalInventory::Amazon
  class Iterator
    include Logging

    attr_reader :block, :error_message, :log

    def initialize(blk, error_message)
      @block         = blk
      @error_message = error_message
      @log           = Logger.new(STDOUT)
    end

    def each
      block.call do |entity|
        yield(entity)
      end
    rescue => e
      logger.warn("#{error_message}. Message: #{e.message}")
      []
    end
  end
end
