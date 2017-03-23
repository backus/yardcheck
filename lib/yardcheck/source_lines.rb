# frozen_string_literal: true

module Yardcheck
  class SourceLines
    include Concord.new(:lines)

    def self.process(contents)
      new(
        contents.split("\n").map do |line|
          line.gsub(/^\s+/, '')
        end
      )
    end

    def documentation_above(line)
      first_line = last_line = line - 1

      first_line -= 1 until first_line.equal?(0) || line(first_line) !~ /^\s*#/

      lines[first_line..(last_line - 1)]
    end

    private

    def line(number)
      lines.fetch(number - 1)
    end
  end # SourceLines
end # Yardcheck
