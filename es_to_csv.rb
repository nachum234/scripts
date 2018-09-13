#!/usr/bin/env ruby
require 'elasticsearch'
require 'json'
#######################################
#
# Main
#
#######################################
t = Time.new(2018, 7, 22)
start_time = (t.to_f * 1000).to_i
end_time = (t.to_f * 1000).to_i + 86399999
client = Elasticsearch::Client.new host: 'gsr-elastic.geosurf.io'

response = client.search index: '_all', scroll: '5m', size: 1000,
body: {
  "version": true,
  "size": 1000,
  "sort": [
    {
      "@timestamp": {
        "order": "desc",
        "unmapped_type": "boolean"
      }
    }
  ],
  "_source": {
    "excludes": []
  },
  "aggs": {
    "2": {
      "date_histogram": {
        "field": "@timestamp",
        "interval": "30m",
        "time_zone": "Asia/Jerusalem",
        "min_doc_count": 1
      }
    }
  },
  "stored_fields": [
    "*"
  ],
  "script_fields": {
    "bytes_overall": {
      "script": {
        "inline": "doc['bytes_read'].value + doc['bytes_uploaded'].value",
        "lang": "painless"
      }
    }
  },
  "docvalue_fields": [
    "@timestamp",
    "received_at"
  ],
  "query": {
    "bool": {
      "must": [
        {
          "query_string": {
            "query": "bytes_read: [0 TO *] AND group_id: 6895",
            "analyze_wildcard": true,
            "default_field": "*"
          }
        },
        {
          "range": {
            "@timestamp": {
              "gte": start_time,
              "lte": end_time,
              "format": "epoch_millis"
            }
          }
        }
      ],
      "filter": [],
      "should": [],
      "must_not": []
    }
  },
  "highlight": {
    "pre_tags": [
      "@kibana-highlighted-field@"
    ],
    "post_tags": [
      "@/kibana-highlighted-field@"
    ],
    "fields": {
      "*": {}
    },
    "fragment_size": 2147483647
  }
}

puts response['hits']['hits'].map { |r| "#{r['_source']['time_stamp']},#{r['_source']['group_id']},#{r['_source']['response_code']},#{r['_source']['client_ip']},#{r['fields']['bytes_overall'][0]},#{r['_source']['domain']}" }
while response = client.scroll(scroll_id: response['_scroll_id'], scroll: '5m') and not response['hits']['hits'].empty? do
  puts response['hits']['hits'].map { |r| "#{r['_source']['time_stamp']},#{r['_source']['group_id']},#{r['_source']['response_code']},#{r['_source']['client_ip']},#{r['fields']['bytes_overall'][0]},#{r['_source']['domain']}" }
end
