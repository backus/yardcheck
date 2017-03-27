# frozen_string_literal: true

module TestApp
  class TracepointBug
    SomeError = Class.new(StandardError)

    # @return [Integer]
    def method1
      method2
    rescue SomeError => error
      foo # resolve ambiguous raise state
      return 1
    end

    def foo
      1
    end

    def method2
      raise SomeError
    end
  end
end
