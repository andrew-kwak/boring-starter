# Slow AI belongs in a queue, not a request (Rule #16).
#
# Claim to dedupe; release to recover. The atomic UPDATE is the lock —
# the database picks the winner, so concurrent workers can't both call
# the model, and a transient failure never strands the row in :running.
class SummarizeJob < ApplicationJob
  retry_on LlmTimeout, wait: :polynomially_longer,
    attempts: 3
  # be polite to the provider
  limits_concurrency key: "llm", to: 5

  def perform(summary)
    # Claim the work atomically. Only ONE worker can
    # move a row out of :queued, so duplicates lose the
    # race and stop. A bare `return if summary.done?` is
    # check-then-act — two runs could both read "not
    # done" and both call the model. The affected-row
    # count is the lock; the database picks the winner.
    claimed = Summary
      .where(id: summary.id, status: :queued)
      .update_all(status: :running) == 1
    # not claimed = a genuine duplicate: already
    # running or done
    return unless claimed
    begin
      summary.update!(body: Llm.ask(summary.prompt),
        status: :done)
    rescue => e
      # Don't strand the row in :running on a transient
      # failure. Release it back to :queued so the retry
      # above can legitimately re-claim it next time.
      Summary
        .where(id: summary.id, status: :running)
        .update_all(status: :queued)
      raise e
    end
  end
end
