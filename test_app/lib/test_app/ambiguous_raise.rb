# frozen_string_literal: true

module TestApp
  module AmbiguousRaise
    SomeError = Class.new(StandardError)

    # @return [Integer]
    def self.method1
      method2
    end

    # @return [Integer]
    def self.method2
      method3
    rescue SomeError
      2
    end

    # @return [Integer]
    def self.method3
      method4

      3
    end

    # @return [Integer]
    def self.method4
      raise SomeError

      4
    end
  end
end
