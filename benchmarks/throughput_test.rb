#!/usr/bin/env ruby
# Measures sustained throughput: N worker threads hammer the ingest
# endpoint concurrently for a fixed duration, each holding one persistent
# HTTP connection. Total completed requests / elapsed seconds = req/sec.
#
# This is the pure-Ruby equivalent of what `wrk` measures — no external
# tool required, same underlying idea: many concurrent connections,
# count completions over a time window.
#
# Run: ruby throughput_test.rb [http://localhost:3000] [threads] [duration_seconds]

require "net/http"
require "json"
require "uri"
require "securerandom"

base_url = ARGV[0] || "http://localhost:3000"
thread_count = (ARGV[1] || 20).to_i
duration = (ARGV[2] || 10).to_i

uri = URI.parse("#{base_url}/api/v1/webhooks/loadtest")

completed = Concurrent = { count: 0 }
mutex = Mutex.new
stop_at = nil

def build_payload(i)
  {
    event_type: ["order.created", "user.signup", "payment.failed"].sample,
    request_index: i,
    nested: { a: rand(1000), b: SecureRandom.hex(8) }
  }.to_json
rescue StandardError
  { request_index: i }.to_json
end

puts "Warming up..."
warm_http = Net::HTTP.new(uri.host, uri.port)
warm_http.start
2.times do |i|
  req = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" })
  req.body = build_payload(i)
  warm_http.request(req)
end
warm_http.finish

puts "Running #{thread_count} threads for #{duration}s against #{uri}..."

start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
stop_at = start_time + duration

threads = Array.new(thread_count) do |t|
  Thread.new do
    http = Net::HTTP.new(uri.host, uri.port)
    http.start
    local_count = 0
    i = 0
    while Process.clock_gettime(Process::CLOCK_MONOTONIC) < stop_at
      req = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" })
      req.body = build_payload(i)
      begin
        res = http.request(req)
        local_count += 1 if res.code.to_i == 201
      rescue StandardError => e
        warn "Thread #{t} error: #{e.class}"
      end
      i += 1
    end
    http.finish if http.started?
    mutex.synchronize { completed[:count] += local_count }
  end
end

threads.each(&:join)
elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

rps = (completed[:count] / elapsed).round(1)

puts ""
puts "Completed requests: #{completed[:count]}"
puts "Elapsed:             #{elapsed.round(2)}s"
puts "Throughput:          #{rps} req/sec"
puts ""
puts "This is your real bullet-2 number — replace the placeholder with it."