# encoding: utf-8
# frozen_string_literal: true

module RuboCop
  module Cop
    module Style
      # This cop enforces square brackets for Array literal `%`-style
      # delimiters.
      #
      # @example
      #
      #   # bad
      #   %w(foo bar) + %w{baz qux}
      #
      #   # good
      #   %w[foo bar] + %w[baz qux]
      class ArrayLiteralDelimiter < RuboCop::Cop::Cop
        def on_array(*args)
          array = args.first

          first, last = array.loc.begin, array.loc.end

          return unless first && last
          return unless first.source.start_with?('%')

          return if first.source.start_with?('%w[', '%W[', '%i[', '%I[') &&
            last.source == ']'

          add_offense(array, :expression, "TODO")
        end

        def autocorrect(node)
          -> (corrector) do
            style = node.loc.begin.source[0..-2]

            corrector.replace(node.loc.begin, "#{style}[")
            corrector.replace(node.loc.end, ']')
          end
        end
      end
    end
  end
end
