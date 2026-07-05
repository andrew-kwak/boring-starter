# An agent is a loop with a budget. Everything else is columns (Rule #14).
#
# `steps_remaining?` is the single most important line: a step counter is the
# simplest budget and the right place to start. In real use, cap the axes that
# actually cost you — tokens, dollars, wall-clock — each a column checked in
# the same loop. An agent without a budget isn't autonomous; it's unsupervised.
class AgentRunJob < ApplicationJob
  retry_on LlmTimeout, wait: :polynomially_longer,
    attempts: 3

  def perform(run)
    run.running! if run.queued?
    while run.running? && run.steps_remaining?
      action = Llm.next_action(run)  # the model
      result = run.execute(action)  # plain Ruby method
      run.agent_steps.create!(action:, result:)
      run.done! if action.final?
      run.broadcast_progress         # Turbo Stream to UI
    end
    run.out_of_budget! if run.running?  # budget enforced
  rescue => e
    # Any step can blow up — a context-length overflow,
    # a bad tool call, a provider 500. Never let it
    # strand the run in :running. Fail it cleanly so the
    # UI updates and a human (or a retry) can see what
    # happened.
    if run.running?
      run.update!(status: :failed, error: e.message)
    end
    raise e
  end
end
