# frozen_string_literal: true

require 'test_app/ambiguous_raise'
require 'test_app/block_return'
require 'test_app/tracepoint_bug'

module TestApp
  class Namespace
    # Singleton method with correct param definition and incorrect return
    #
    # @param left [Integer]
    # @param right [Integer]
    #
    # @return [String]
    def self.add(left, right)
      left + right
    end

    # Instance method with correct param definition and incorrect return
    #
    # @param left [Integer]
    # @param right [Integer]
    #
    # @return [String]
    def add(left, right)
      left + right
    end

    # Untested method with documentation
    #
    # @param str [String]
    #
    # @return [String]
    def untested_method(str)
    end

    def undocumented
    end

    # @param foo [What]
    #
    # @return [Wow]
    def ignoring_invalid_types(foo)
    end

    # @return [TestApp::Namespace::Parent]
    def returns_generic
      Child.new
    end

    # @return [Child]
    def documents_relative
      'str'
    end

    # @param foo but not type definition in brackets
    # @return no type specified here
    def tags_without_types(foo)
    end

    # @param [String]
    def param_without_name(unnamed)
    end

    # @return [nil]
    def return_nil
    end

    # @return [Namespace]
    def return_self
      self
    end

    # @return [undefined]
    def undefined_return
    end

    # @return [Boolean]
    def bool_return
    end

    # @return [Array<String>]
    def array_return
    end

    # @return [String] in some cases
    # @return [nil] otherwise
    def multiple_returns
    end

    # @param list [Enumerable<Integer>]
    # @return [nil]
    def enumerable_param(list)
    end

    # @param value [String]
    # @return [nil]
    def properly_tested_with_instance_double(value)
    end

    # @param value [String]
    # @return [nil]
    def improperly_tested_with_instance_double(value)
    end

    AppError = Class.new(StandardError)

    # @return [Fixnum]
    def always_raise
      raise AppError

      1
    end

    # @return [:foo]
    def returns_literal_symbol
      :foo
    end

    # This should be ignored since truthy and falsey values are all values
    #
    # @return [Boolean]
    def truthy_predicate?
      1
    end

    class Parent
    end

    class Child < Parent
    end
  end
end
