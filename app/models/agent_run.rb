# Agent state is a database row, not a mystery inside a framework (ch. 14).
# Query it, admin it, debug it with the console. Every step is recorded:
# your audit log, your debugging trail, and your eval dataset — one has_many.
class AgentRun < ApplicationRecord
  belongs_to :user
  has_many :agent_steps
  enum :status, { queued: 0, running: 1, done: 2,
    failed: 3, out_of_budget: 4 }
end
