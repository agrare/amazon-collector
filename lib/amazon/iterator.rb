module Amazon
  class Iterator
    attr_reader :block, :error_message, :log

    def initialize(blk, error_message)
      @block         = blk
      @error_message = error_message
      @log           = Logger.new(STDOUT)
    end

    def each(&blk)
      block.call do |entity|
        blk.call(entity)
      end
    rescue => e
      log.warn("#{error_message}. Message: #{e.message}")
      []
    end
  end
end
