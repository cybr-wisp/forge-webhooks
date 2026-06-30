class CreateWebhookEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :webhook_events do |t|
      t.string   :source,      null: false
      t.jsonb    :payload,     null: false, default: {}
      t.string   :http_method, default: "POST"
      t.integer  :status_code
      t.timestamps
    end

    # GIN index lets you query inside the JSONB blob (payload->>'event_type', etc.)
    # without it every containment query is a full table scan.
    add_index :webhook_events, :payload, using: :gin
    add_index :webhook_events, :source
    add_index :webhook_events, :created_at
  end
end
