RSpec.describe TopologicalInventory::Amazon::CollectorsPool do
  let(:source) { double("Source") }

  subject { described_class.new(nil, nil) }

  describe ".source_valid?" do
    it "returns false if any of source, username, password are blank" do
      (-1..2).each do |nil_index|
        data = (0..2).collect { |j| nil_index == j ? nil : 'some_data' }
        allow(source).to receive_messages(:source => data[0])
        secret = { "username" => data[1], "password" => data[2] }

        expect(subject.source_valid?(source, secret)).to eq(nil_index == -1)
      end
    end
  end
end
