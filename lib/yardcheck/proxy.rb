# frozen_string_literal: true

module Yardcheck
  class Proxy < BasicObject
    def initialize(target)
      @target = target
    end

    undef_method :==
    undef_method :!=
    undef_method :!

    def method_missing(method_name, *args, &block)
      if respond_to_missing?(method_name, true)
        @target.__send__(method_name, *args, &block)
      else
        ::Object
          .instance_method(method_name)
          .bind(@target)
          .call(*args, &block)
      end
    end

    def respond_to_missing?(method_name, include_all = false)
      ::Object
        .instance_method(:respond_to?)
        .bind(@target)
        .call(method_name, include_all)
    end

    private

    def object_dispatch(receiver, method_name, *params)
      ::Object
        .instance_method(method_name)
        .bind(receiver)
        .call(*params)
    end
  end # Proxy
end # Yardcheck
