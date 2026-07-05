# CONVENTIONS.md — standing orders for humans and agents
1. Rails 8 defaults are law: Solid Queue (not Sidekiq),
   built-in auth (not Devise), Hotwire (not React).
2. SQLite in production until a measured number
   says otherwise.
3. Three models until users demand a fourth.
4. Every LLM call goes through app/models/llm.rb.
   No exceptions.
5. Slow work goes in a job. Streaming only for a
   blinking cursor.
6. Additive migrations first; destructive ones a
   deploy later.
7. New gems require a named, measured pain.
8. bin/ci green before any deploy.
9. If a diff is too big to read, it's too big to ship.
10. Logic and its tests never come from the same breath:
    human specs the test first, or human adds the
    hostile cases.
11. When unsure: the boring option.
