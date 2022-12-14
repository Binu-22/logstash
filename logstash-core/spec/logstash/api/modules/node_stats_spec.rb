# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "spec_helper"

require "sinatra"
require "logstash/api/modules/node_stats"

describe LogStash::Api::Modules::NodeStats do
  include_context "api setup"
  include_examples "not found"

  extend ResourceDSLMethods

  # DSL describing response structure
  root_structure = {
    "jvm"=>{
      "uptime_in_millis" => Numeric,
      "threads"=>{
        "count"=>Numeric,
        "peak_count"=>Numeric
      },
      "gc" => {
        "collectors" => {
          "young" => {
            "collection_count" => Numeric,
            "collection_time_in_millis" => Numeric
          },
          "old" => {
            "collection_count" => Numeric,
            "collection_time_in_millis" => Numeric
          }
        }
      },
      "mem" => {
        "heap_used_in_bytes" => Numeric,
        "heap_used_percent" => Numeric,
        "heap_committed_in_bytes" => Numeric,
        "heap_max_in_bytes" => Numeric,
        "non_heap_used_in_bytes" => Numeric,
        "non_heap_committed_in_bytes" => Numeric,
        "pools" => {
          "survivor" => {
            "peak_used_in_bytes" => Numeric,
            "used_in_bytes" => Numeric,
            "peak_max_in_bytes" => Numeric,
            "max_in_bytes" => Numeric
          },
          "old" => {
            "peak_used_in_bytes" => Numeric,
            "used_in_bytes" => Numeric,
            "peak_max_in_bytes" => Numeric,
            "max_in_bytes" => Numeric
          },
          "young" => {
            "peak_used_in_bytes" => Numeric,
            "used_in_bytes" => Numeric,
            "peak_max_in_bytes" => Numeric,
            "max_in_bytes" => Numeric
          }
        }
      }
    },
    "process"=>{
      "peak_open_file_descriptors"=>Numeric,
      "max_file_descriptors"=>Numeric,
      "open_file_descriptors"=>Numeric,
      "mem"=>{
        "total_virtual_in_bytes"=>Numeric
      },
      "cpu"=>{
        "total_in_millis"=>Numeric,
        "percent"=>Numeric,
        # load_average is not supported on Windows, set it below
      }
   },
   "events" => {
      "duration_in_millis" => Numeric,
      "in" => Numeric,
      "filtered" => Numeric,
      "out" => Numeric,
      "queue_push_duration_in_millis" => Numeric
   },
   "flow" => {
      "output_throughput" => Hash,
      "filter_throughput" => Hash,
      "queue_backpressure" => Hash,
      "worker_concurrency" => Hash,
      "input_throughput" => Hash
   },
   "pipelines" => {
     "main" => {
       "events" => {
         "duration_in_millis" => Numeric,
         "in" => Numeric,
         "filtered" => Numeric,
         "out" => Numeric,
         "queue_push_duration_in_millis" => Numeric
       },
       "flow" => {
         "output_throughput" => Hash,
         "filter_throughput" => Hash,
         "queue_backpressure" => Hash,
         "worker_concurrency" => Hash,
         "input_throughput" => Hash
       },
       "plugins" => {
          "inputs" => Array,
          "codecs" => Array,
          "filters" => Array,
          "outputs" => Array,
       },
     }
   },
   "reloads" => {
     "successes" => Numeric,
     "failures" => Numeric
   },
   "os" => Hash,
   "queue" => {
      "events_count" => Numeric
   }
  }

  unless LogStash::Environment.windows?
    root_structure["process"]["cpu"]["load_average"] = { "1m" => Numeric }
  end

  test_api_and_resources(root_structure)
end
