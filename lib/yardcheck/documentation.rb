# frozen_string_literal: true

module Yardcheck
  class Documentation
    include Concord.new(:yardocs), Memoizable

    def self.load_yard
      # YARD doesn't write to .yardoc/ without this lock_for_writing and save
      YARD::Registry.lock_for_writing do
        YARD.parse(['lib/**/*.rb'], [], YARD::Logger::ERROR)
        YARD::Registry.save(true)
      end

      YARD::Registry.load!
    end

    def self.parse
      load_yard
      new(YARD::Registry.all(:method))
    end

    def method_objects
      yardocs.map { |yardoc| MethodObject.new(yardoc) }
    end
  end # Documentation
end # Yardcheck
