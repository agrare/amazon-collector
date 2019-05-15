require "topological_inventory/amazon/collector/application_metrics"
require "active_support/core_ext/string"
require "net/http"

RSpec.describe TopologicalInventory::Amazon::Collector::ApplicationMetrics do
  subject! { described_class.new(9394) }
  after    { subject.stop_server }

  it "exposes metrics" do
    subject.record_error
    subject.record_error

    metrics = get_metrics
    expect(metrics["topological_inventory_amazon_collector_errors_total"]).to eq("2")
  end

  def get_metrics
    metrics = Net::HTTP.get(URI("http://localhost:9394/metrics")).split("\n").delete_if do |e|
      e.blank? || e.start_with?("#")
    end

    metrics.each_with_object({}) do |m, hash|
      k, v = m.split
      hash[k] = v
    end
  end
end
