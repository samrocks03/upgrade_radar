# frozen_string_literal: true

module UpgradeRadar
  module Runtime
    class RubyWarningHook
      def self.install(collector)
        Warning[:deprecated] = true if Warning.respond_to?(:[]=)

        hook = Module.new do
          define_method(:warn) do |message, category: nil, **|
            if category == :deprecated
              collector.add(message, source: :ruby, backtrace: caller)
            end
            super(message, category: category)
          end
        end

        Warning.extend(hook)
      end
    end
  end
end
