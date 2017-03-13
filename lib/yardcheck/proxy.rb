module Yardcheck
  class Proxy < BasicObject
    def initialize(target)
      @target = target
    end

    undef_method :==
    undef_method :!=
    undef_method :!

    def method_missing(method_name, *args, &block)
      if target_respond_to?(method_name)
        @target.send(method_name, *args, &block)
      else
        ::Object
          .instance_method(method_name)
          .bind(@target)
          .call(*args, &block)
      end
    end

    private

    def target_respond_to?(method_name)
      ::Object
        .instance_method(:respond_to?)
        .bind(@target)
        .call(method_name, true)
    end
  end
end
