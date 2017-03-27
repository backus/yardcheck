# frozen_string_literal: true

module Yardcheck
  class ProcessedSource
    include Concord.new(:raw_source)
    include Adamantium::Flat

    # @see https://bugs.ruby-lang.org/issues/13369
    def tracepoint_bug_candidate?
      resbodies = find_resbodies
      resbodies.any? do |node|
        find_type(node, :return).any?
      end
    end

    private

    def find_resbodies(node = ast)
      find_type(node, :resbody)
    end

    def find_type(node, type)
      return nil unless node.is_a?(Parser::AST::Node)
      return [node] if node.type == type

      node.children.map { |child| find_type(child, type) }.flatten.compact
    end

    def ast
      Parser::CurrentRuby.parse(raw_source)
    end
  end # ProcessedSource
end # Yardcheck
