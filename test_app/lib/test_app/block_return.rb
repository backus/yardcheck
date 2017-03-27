# frozen_string_literal: true

module TestApp
  module BlockReturn
    SomeError = Class.new(StandardError)

    # @return [Integer]
    def self.entrypoint
      method_that_executes_normal_block do
        1
      end

      method_that_passes_block_with_return_keyword_along do
        return 1
      end

      'foo'
    end

    # @return [Integer]
    def self.method_that_passes_block_with_return_keyword_along(&block)
      method_that_yield_block_with_return_keyword(&block)

      2
    end

    # @return [Integer]
    def self.method_that_yield_block_with_return_keyword
      yield

      3
    end

    def self.method_that_executes_normal_block
      yield

      4
    end
  end
end
