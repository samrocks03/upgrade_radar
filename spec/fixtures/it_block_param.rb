# frozen_string_literal: true

class DataProcessor
  def process(items)
    items.map { it.to_s }
    items.select { it > 0 }
    items.each { |item| item.process }
  end
end
