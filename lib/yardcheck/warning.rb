# frozen_string_literal: true

module Yardcheck
  class Warning
    extend Color
    include Concord.new(:method_object, :typedef)

    MSG = "#{red('WARNING:')} Unabled to resolve #{yellow('%<typedef>s')} for %<location>s"

    def message
      format(MSG, typedef: typedef.signature, location: method_object.location_pointer)
    end
  end
end
