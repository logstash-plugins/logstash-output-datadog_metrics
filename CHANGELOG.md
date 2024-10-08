## 3.0.6
  - Add `api_url` config option to allow usage in different regions [#13](https://github.com/logstash-plugins/logstash-output-datadog_metrics/pull/13)

## 3.0.5
  - Change `api_key` config type to `password` to prevent leaking in debug logs [#18](https://github.com/logstash-plugins/logstash-output-datadog_metrics/pull/18)

## 3.0.4
  - Docs: Set the default_codec doc attribute.

## 3.0.3
  - Update gemspec summary

## 3.0.2
  - Fix some documentation issues

## 3.0.0
  - Update to the new logstash event api
  - update the travis file
  - relax constraints on the logstash-core-plugin-api
  - add logstash-codec-plain as a runtime dependency

## 2.0.4
  - Depend on logstash-core-plugin-api instead of logstash-core, removing the need to mass update plugins on major releases of logstash

## 2.0.3
  - New dependency requirements for logstash-core for the 5.0 release

## 2.0.0
 - Plugins were updated to follow the new shutdown semantic, this mainly allows Logstash to instruct input plugins to terminate gracefully, 
   instead of using Thread.raise on the plugins' threads. Ref: https://github.com/elastic/logstash/pull/3895
 - Dependency on logstash-core update to 2.0

## 0.1.5
 - use new Json and Timestamp API
 - better coersion of the event.timestamp: can be Time, Timestamp or String
