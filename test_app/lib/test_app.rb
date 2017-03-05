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
    # @return [Array<Integer>]
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

    # @return no type specified here
    def return_tag_without_type
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

    class Parent
    end

    class Child < Parent
    end
  end
end
