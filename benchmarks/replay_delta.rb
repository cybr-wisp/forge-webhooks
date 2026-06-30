#!/usr/bin/env ruby
# Times the 1-click replay endpoint against a scripted approximation of the
# "manual Postman" workflow: open saved request, verify body against DB,
# hit send, read response. We can't literally automate clicking through
# Postman's UI, so the manual baseline times the equivalent steps done by
# hand via separate, sequential API/script calls — which is the honest
# floor for "manual," since a human is strictly slower than a script doing
# the same steps with zero think-time.
#
# Run: ruby replay_delta.rb [http://localhost:3000] [target_webhook_id]

require "net/http"
require "json"
require "uri"

base_url   = ARGV[0] || "http://localhost:3000"
webhook_id = ARGV[1] || raise("Usage: ruby replay_delta.rb <base_url> <webhook_id>")
target_url = ENV.fetch("REPLAY_TARGET", "http://localhost:3000/api/v1/webhooks/replay-target")

def time_it
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  yield
  ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round(2)
end

http = ->(uri_str, method: :get, body: nil) {
  uri = URI.parse(uri_str)
  h = Net::HTTP.new(uri.host, uri.port)
  req = method == :post ? Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" }) : Net::HTTP::Get.new(uri.request_uri)
  req.body = body.to_json if body
  h.request(req)
}

# --- 1-click replay ---
one_click_ms = time_it do
  http.call("#{base_url}/api/v1/webhooks/#{webhook_id}/replays", method: :post, body: { target_url: target_url })
end

# --- scripted "manual" baseline: fetch event, parse, re-send separately ---
manual_ms = time_it do
  res = http.call("#{base_url}/api/v1/webhooks/#{webhook_id}")
  event = JSON.parse(res.body)
  payload = event["payload"]
  http.call(target_url, method: :post, body: payload)
end

reduction_pct = (((manual_ms - one_click_ms) / manual_ms) * 100).round(1)

puts "1-click replay:     #{one_click_ms} ms"
puts "Scripted manual:    #{manual_ms} ms"
puts "Reduction:           #{reduction_pct}%"
puts ""
puts "Note: this measures mechanical steps only — it does NOT include the"
puts "human think-time of finding the right saved request in Postman,"
puts "which is most of the real-world manual cost. If you want a defensible"
puts "number, time yourself doing the manual flow by hand with a stopwatch"
puts "for 5 trials and average it, rather than relying on this script alone."
