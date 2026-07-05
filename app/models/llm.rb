# The single front door for every model call in your app (ch. 15, 18).
#
# Reference shape, not a gem: `client`, `MODELS`, `Usage`, and the error
# classes are yours to wire to your provider. The decisions are the point:
# one door, a timeout, usage recorded, retries delegated to the job layer,
# and a cache scoped so one tenant can never be served another's answer.
class Llm
  # seconds — slow is normal; infinite is not
  TIMEOUT = 30

  def self.ask(prompt, model: "default",
      max_tokens: 1_000)
    response = client.complete(
      prompt:, model: MODELS.fetch(model), max_tokens:,
      timeout: TIMEOUT
    )
    Usage.record!(response)   # tokens & cost
    response.text
  rescue RateLimited, Overloaded => e
    raise Retryable, e  # the job layer retries
  end

  def self.ask_cached(prompt, model: "default",
      scope: :global, ttl: 1.week)
    # `scope` is load-bearing: NEVER let one tenant's
    # cached answer serve another. Default to :global
    # only for truly shared, non-personal content.
    key = ["llm", model, scope,
      Digest::SHA256.hexdigest(prompt)]
    Rails.cache.fetch(key, expires_in: ttl) do
      ask(prompt, model:)
    end
  end
end
