require "manageiq/loggers"

module TopologicalInventory
  module Amazon
    class << self
      attr_writer :logger
    end

    def self.logger
      @logger ||= ManageIQ::Loggers::Container.new
    end

    module Logging
      def logger
        TopologicalInventory::Amazon.logger
      end
    end
  end
end
