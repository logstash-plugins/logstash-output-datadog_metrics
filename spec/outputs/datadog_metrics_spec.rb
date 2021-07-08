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
      '@timestamp' => LogStash::Timestamp.now - 1000
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

  context 'construction' do
    it 'register method calls collaborator methods' do
      expect(http_instance).to receive(:use_ssl=)
      expect(http_instance).to receive(:verify_mode=)
      subject.register
      buffer = subject.instance_variable_get(:@buffer_config)
      expect(buffer[:max_items]).to be 10
    end
  end

  context 'runtime' do
    before do
      allow(http_instance).to receive(:use_ssl=)
      allow(http_instance).to receive(:verify_mode=)
      subject.register
    end

    context 'receiving an event' do
      it 'receives' do
        subject.receive(event)
        buffer = subject.instance_variable_get(:@buffer_state)
        expect(buffer[:pending_items].inspect).to match(/"tags"=>\["foo", "bar"\]/)
        expect(buffer[:pending_items].inspect).to match(/"points"=>\[\[#{LogStash::Timestamp.now.to_i}, 0.0\]\]/)
      end
    end

    context 'flushing multiple counter events' do
      before do
        event_time = LogStash::Timestamp.now
        @dd_metric11 = {
          'metric' => 'metric1',
          'points' => [[event_time.to_i, 1.0]],
          'type' => 'counter',
          'host' => 'localhost',
          'device' => 'device',
          'tags' => ['tag1', 'tag2']
        }
        @dd_metric21 = {
          'metric' => 'metric1',
          'points' => [[event_time.to_i - 1, 1.0]],
          'type' => 'counter',
          'host' => 'localhost',
          'device' => 'device',
          'tags' => ['tag1', 'tag2']
        }
        series_hash = {'series' => [@dd_metric11, @dd_metric11, @dd_metric21]}
        subject.instance_variable_set(:@logger, logger)
        subject.instance_variable_set(:@metric_type, 'counter')
        expect(request).to receive(:body=).with(LogStash::Json.dump({
          series: [ { metric: 'metric1',
                      points: [[ event_time.to_i, 2.0 ]],
                      type: 'counter',
                      host: 'localhost',
                      device: 'device',
                      tags: [ 'tag1', 'tag2' ] },
                    { metric: 'metric1',
                      points: [[ event_time.to_i - 1, 1.0 ]],
                      type: 'counter',
                      host: 'localhost',
                      device: 'device',
                      tags: [ 'tag1', 'tag2' ] } ] }))
        expect(request).to receive(:add_field)
        expect(logger).to receive(:info).at_least(:once)
        expect(logger).not_to receive(:warn)
        expect(http_instance).to receive(:request).with(request).and_return(response)

        expect(response).to receive(:code).and_return('202')
      end

      it 'flushes and aggregate identical events' do
        subject.flush([@dd_metric11, @dd_metric11, @dd_metric21], false)
      end
    end

    context 'flushing multiple gauge events' do
      before do
        event_time = LogStash::Timestamp.now
        @dd_metric11 = {
          'metric' => 'metric1',
          'points' => [[event_time.to_i, 1.0]],
          'type' => 'gauge',
          'host' => 'localhost',
          'device' => 'device',
          'tags' => ['tag1', 'tag2']
        }
        @dd_metric21 = {
          'metric' => 'metric1',
          'points' => [[event_time.to_i - 1, 1.0]],
          'type' => 'gauge',
          'host' => 'localhost',
          'device' => 'device',
          'tags' => ['tag1', 'tag2']
        }
        series_hash = {'series' => [@dd_metric11, @dd_metric11, @dd_metric21]}
        subject.instance_variable_set(:@logger, logger)
        subject.instance_variable_set(:@metric_type, 'gauge')
        expect(request).to receive(:body=).with(LogStash::Json.dump({
          series: [ { metric: 'metric1',
                      points: [[ event_time.to_i, 1.0 ]],
                      type: 'gauge',
                      host: 'localhost',
                      device: 'device',
                      tags: [ 'tag1', 'tag2' ] }, 
                    { metric: 'metric1',
                      points: [[ event_time.to_i, 1.0 ]],
                      type: 'gauge',
                      host: 'localhost',
                      device: 'device',
                      tags: [ 'tag1', 'tag2' ] },
                    { metric: 'metric1',
                      points: [[ event_time.to_i - 1, 1.0 ]],
                      type: 'gauge',
                      host: 'localhost',
                      device: 'device',
                      tags: [ 'tag1', 'tag2' ] } ] }))
        expect(request).to receive(:add_field)
        expect(logger).to receive(:info).at_least(:once)
        expect(logger).not_to receive(:warn)
        expect(http_instance).to receive(:request).with(request).and_return(response)

        expect(response).to receive(:code).and_return('202')
      end

      it 'flushes and send all events as is' do
        subject.flush([@dd_metric11, @dd_metric11, @dd_metric21], false)
      end
    end
  end

end
