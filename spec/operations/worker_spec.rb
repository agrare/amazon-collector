require "topological_inventory/amazon/operations/worker"

RSpec.describe TopologicalInventory::Amazon::Operations::Worker do
  describe "#run" do
    let(:client) { double("ManageIQ::Messaging::Client") }
    let(:subject) { described_class.new }
    before do
      require "manageiq-messaging"
      allow(ManageIQ::Messaging::Client).to receive(:open).and_return(client)
      allow(client).to receive(:close)
    end

    it "calls subscribe_topic on the right queue" do
      operations_topic = "platform.topological-inventory.operations-amazon"

      message = double("ManageIQ::Messaging::ReceivedMessage")
      allow(message).to receive(:ack)

      expect(client).to receive(:subscribe_topic)
        .with(hash_including(:service => operations_topic)).and_yield(message)
      expect(TopologicalInventory::Amazon::Operations::Processor)
        .to receive(:process!).with(message)
      subject.run
    end
  end
end
