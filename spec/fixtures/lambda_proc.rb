# frozen_string_literal: true

class EventHandler
  def setup
    handler = proc { |event| process(event) }
    callback = lambda(&handler)
    callback
  end
end
