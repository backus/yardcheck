module Yardcheck
  class Proxy < BasicObject
    def initialize(target)
      @target = target
    end

    def method_missing(method_name, *args, &block)
      ::Object.instance_method(method_name).bind(@target).call(*args, &block)
    end
  end
end
