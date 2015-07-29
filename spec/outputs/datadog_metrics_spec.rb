require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/datadog_metrics"

describe LogStash::Outputs::DatadogMetrics do
  let(:http_instance) { double('net_http_instance') }
  let(:request) { double('net_http_request') }
  let(:response) { double('net_http_response') }

  let(:json_obj) { double('json_obj') }
  let(:logger) { double('logger') }
  let(:ddtags) { ['foo', 'bar'] }
  let(:event_hash) do
    {
      'message' => 'Hello world!',
      'source' => 'datadog-metrics',
      'type' => 'generator',
      'host' => 'localhost',
      '@timestamp' => LogStash::Timestamp.now
    }
  end
  let(:event)  { LogStash::Event.new(event_hash) }
  let(:params) do
    {
      'api_key' => '123456789',
      'dd_tags' => ddtags,
      'metric_type' => 'gauge'
    }
  end

  before do
    allow(Net::HTTP).to receive(:new).and_return(http_instance)
    allow(Net::HTTP::Post).to receive(:new).and_return(request)
  end

  subject { described_class.new(params) }

  before do
    expect(http_instance).to receive(:use_ssl=)
    expect(http_instance).to receive(:verify_mode=)
    subject.register
  end

  context 'construction' do
    it 'register method calls collaborator methods' do
      buffer = subject.instance_variable_get(:@buffer_config)
      expect(buffer[:max_items]).to be 10
    end
  end

  context 'runtime' do
    context 'receiving an event' do
      it 'receives' do
        subject.receive(event)
        buffer = subject.instance_variable_get(:@buffer_state)
        expect(buffer[:pending_items].inspect).to match(/"tags"=>\["foo", "bar"\]/)
      end
    end

    context 'flushing multiple events' do
      before do
        series_hash = {'series' => Array(event)}
        subject.instance_variable_set(:@logger, logger)
        expect(LogStash::Json).to receive(:dump).with(series_hash).and_return('---')
        expect(request).to receive(:body=)
        expect(request).to receive(:add_field)
        expect(logger).to receive(:info).at_least(:once)
        expect(logger).not_to receive(:warn)
        expect(http_instance).to receive(:request).with(request).and_return(response)

        expect(response).to receive(:code).and_return('202')
      end

      it 'flushes final=false [final is unused]' do
        expect{subject.flush([event], false)}.not_to raise_error
      end

      it 'flushes final=true [final is unused]' do
        expect{subject.flush([event], true)}.not_to raise_error
      end
    end
  end

end
