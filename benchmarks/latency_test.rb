#!/usr/bin/env ruby
# Measures real write latency: 50 sequential POSTs to the ingest endpoint,
# each with a small varied JSONB payload. Prints avg / median / p95 in ms.
#
# Uses one persistent HTTP connection (http.start/finish) instead of
# reconnecting per-request — a fresh TCP handshake per request is what a
# real webhook consumer would never do, and it swamps the real DB write
# time with connection-setup overhead, especially on Windows loopback.
#
# Also discards the first 2 requests as warmup — Rails lazily compiles
# routes/classes on the first hit in any process, which is a one-time
# cost, not part of steady-state write latency.
#
# Run: ruby latency_test.rb [http://localhost:3000] [50]

require "net/http"
require "json"
require "uri"
require "securerandom"

base_url = ARGV[0] || "http://localhost:3000"
n        = (ARGV[1] || 50).to_i
warmup   = 2

uri = URI.parse("#{base_url}/api/v1/webhooks/benchmark")
http = Net::HTTP.new(uri.host, uri.port)
http.start

latencies = []

(n + warmup).times do |i|
  random_suffix = begin
    SecureRandom.hex(8)
  rescue StandardError
    "x#{i}"
  end

  payload = {
    event_type: ["order.created", "user.signup", "payment.failed"].sample,
    request_index: i,
    nested: { a: rand(1000), b: random_suffix }
  }.to_json

  req = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" })
  req.body = payload

  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  res = http.request(req)
  t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)

  unless res.code.to_i == 201
    warn "Request #{i} failed: #{res.code} #{res.body}"
    next
  end

  next if i < warmup

  latencies << (t1 - t0) * 1000.0
end

http.finish if http.started?

latencies.sort!
avg    = (latencies.sum / latencies.size).round(2)
median = latencies[latencies.size / 2].round(2)
p95    = latencies[(latencies.size * 0.95).to_i.clamp(0, latencies.size - 1)].round(2)

puts "Requests measured: #{latencies.size} (+#{warmup} warmup, discarded)"
puts "Avg write latency:    #{avg} ms"
puts "Median write latency: #{median} ms"
puts "p95 write latency:    #{p95} ms"
puts ""
puts "Use the AVG figure for the resume bullet — it's the one that matches"
puts "how 'average latency over N requests' is conventionally reported."