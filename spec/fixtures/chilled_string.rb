# frozen_string_literal: false

class StringMutator
  def mutate
    greeting = "hello"
    greeting << " world"
    "test".gsub!("t", "T")
    "data".replace("new data")
  end
end
