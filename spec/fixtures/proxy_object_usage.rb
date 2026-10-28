# frozen_string_literal: true

class LazyLoader < ActiveSupport::ProxyObject
  def initialize(&block)
    @block = block
  end

  def method_missing(name, *args, &block)
    @target ||= @block.call
    @target.send(name, *args, &block)
  end
end
