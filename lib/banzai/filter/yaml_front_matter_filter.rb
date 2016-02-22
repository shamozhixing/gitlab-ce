require 'html/pipeline/filter'
require 'yaml'

module Banzai
  module Filter
    class YamlFrontMatterFilter < HTML::Pipeline::Filter
      DELIM = '---'.freeze

      # Hat-tip to Middleman: https://git.io/v2e0z
      PATTERN = %r{
        \A(?:[^\r\n]*coding:[^\r\n]*\r?\n)?
        (?<start>#{DELIM})[ ]*\r?\n
        (?<frontmatter>.*?)[ ]*\r?\n?
        ^(?<stop>#{DELIM})[ ]*\r?\n?
        \r?\n?
        (?<additional_content>.*)
      }mx.freeze

      def call
        match = PATTERN.match(html)

        return html unless match

        frontmatter = load_yaml(match['frontmatter'])

        return html unless frontmatter

        tableize(frontmatter) << match['additional_content']
      end

      private

      def load_yaml(yaml_string)
        YAML.safe_load(yaml_string, [Date, DateTime, Symbol, Time])
      end

      def escape(html)
        ERB::Util.html_escape(html)
      end

      # Converts a YAML object into an HTML table
      #
      # Each row is a key-value pair
      def tableize(yaml)
        table = "<table>\n"

        if yaml.respond_to?(:each_pair)
          yaml.each_pair do |key, value|
            table << "<tr><th>#{escape(key)}</th><td>"

            case value
            when Array
              value.inject(table) { |memo, v| memo << tableize(v) }
            when Hash
              table << tableize(value)
            else
              table << escape(value)
            end

            table << "</td></tr>\n"
          end
        else
          table << "<tr><td>#{escape(yaml)}</td></tr>"
        end

        table << "</table>\n"
      end
    end
  end
end
