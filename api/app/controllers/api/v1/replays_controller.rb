require "net/http"
require "uri"

module Api
  module V1
    class ReplaysController < ApplicationController
      # POST /api/v1/webhooks/:id/replay
      # body: { target_url: "https://example.com/hook" }
      #
      # Re-fires a stored payload at a target endpoint with one request,
      # instead of the manual flow of: open Postman, find the saved request,
      # check the body still matches what's in the DB, hit send, read response.
      def create
        event = WebhookEvent.find(params[:webhook_id])
        target = params.require(:target_url)

        uri = URI.parse(target)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == "https"
        http.open_timeout = 5
        http.read_timeout = 10

        req = Net::HTTP::Post.new(uri.request_uri, { "Content-Type" => "application/json" })
        req.body = event.payload.to_json

        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        response = http.request(req)
        elapsed_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(2)

        render json: {
          replayed_event_id: event.id,
          target: target,
          response_status: response.code,
          elapsed_ms: elapsed_ms
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: "webhook event not found" }, status: :not_found
      rescue => e
        render json: { error: e.message }, status: :bad_gateway
      end
    end
  end
end
