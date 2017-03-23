# frozen_string_literal: true

module Yardcheck
  module Color
    private

    def color(code, text)
      "\e[#{code}m#{text}\e[0m"
    end

    def blue(text)
      color(34, text)
    end

    def red(text)
      color(31, text)
    end

    def yellow(text)
      color(33, text)
    end

    def grey(text)
      color(30, text)
    end
  end # Color
end # Yardcheck
