# Money is the swamp's deepest water. Cross it idempotent, logged,
# and twice-checked (Rule #20).
#
# Record first, act second. The unique index on stripe_id dedupes the
# EVENT RECORD; the job's action must be idempotent on its own (a
# conditional update that no-ops if already paid — never a blind
# increment), and fulfillment keys off the order's own state, not off
# "an event arrived": Stripe retries webhooks and does not guarantee
# event ordering.
class StripeWebhooksController < ApplicationController
  def create
    event = Stripe::Webhook
      .construct_event(payload, sig, secret)
    record = StripeEvent
      .create_or_find_by!(stripe_id: event.id) do |e|
        e.data = event.to_json
      end
    if record.previously_new_record?
      ProcessStripeEventJob.perform_later(record)
    end
    head :ok
  end
end
