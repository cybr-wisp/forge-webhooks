class WebhookEvent < ApplicationRecord
  # `payload` is a jsonb column — Postgres stores it as decomposed binary JSON,
  # which is what makes GIN-indexed querying and write performance reasonable
  # even for arbitrary/unstructured bodies.
  validates :payload, presence: true
  validates :source, presence: true

  scope :recent, -> { order(created_at: :desc) }

  # Cheap fingerprint so the replay tool can show "this looks like a dup"
  # without doing anything fancy.
  def self.ransackable_attributes(_auth_object = nil)
    %w[source created_at]
  end
end
