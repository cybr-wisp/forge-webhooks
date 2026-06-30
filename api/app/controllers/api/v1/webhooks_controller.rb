module Api
  module V1
    class WebhooksController < ApplicationController
      # POST /api/v1/webhooks/:source
      # Accepts ANY JSON body and persists it as-is into the jsonb column.
      # This is the endpoint the latency benchmark hammers.
      def create
        event = WebhookEvent.new(
          source: params[:source],
          payload: request_payload,
          http_method: request.method
        )

        if event.save
          render json: { id: event.id, stored_at: event.created_at }, status: :created
        else
          render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/webhooks
      def index
        events = WebhookEvent.recent.limit(params.fetch(:limit, 50))
        render json: events.as_json(only: [:id, :source, :payload, :status_code, :created_at])
      end

      # GET /api/v1/webhooks/:id
      def show
        event = WebhookEvent.find(params[:id])
        render json: event
      rescue ActiveRecord::RecordNotFound
        render json: { error: "not found" }, status: :not_found
      end

      private

      def request_payload
        # Accept raw JSON body regardless of declared content type — real
        # webhook senders are inconsistent about this.
        raw = request.body.read
        raw.present? ? JSON.parse(raw) : {}
      rescue JSON::ParserError
        { raw: raw }
      end
    end
  end
end
