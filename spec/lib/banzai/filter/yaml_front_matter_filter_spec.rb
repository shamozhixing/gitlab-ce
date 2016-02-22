require 'rails_helper'

describe Banzai::Filter::YamlFrontMatterFilter, lib: true do
  include FilterSpecHelper

  def parse(html)
    Nokogiri::HTML.parse(html)
  end

  it 'allows for `encoding:` before the frontmatter' do
    content = <<-MD.strip_heredoc
      # encoding: UTF-8
      ---
      foo: foo
      ---

      # Header

      Content
    MD

    output = filter(content)

    expect(output).not_to match 'encoding'
  end

  it 'converts YAML frontmatter to a table' do
    content = <<-MD.strip_heredoc
      ---
      foo: foo string
      bar: :bar_symbol
      ---

      # Header

      Content
    MD

    output = parse(filter(content))

    aggregate_failures do
      expect(output.xpath('.//tr[1]/th').text).to eq 'foo'
      expect(output.xpath('.//tr[1]/td').text).to eq 'foo string'
      expect(output.xpath('.//tr[2]/th').text).to eq 'bar'
      expect(output.xpath('.//tr[2]/td').text).to eq 'bar_symbol'
    end
  end

  it 'loads YAML safely' do
    pending "Unsure what we can actually put here to verify this."

    content = <<-MD.strip_heredoc
      ---
      ---
    MD

    expect { filter(content) }.to raise_error(Psych::DisallowedClass)
  end

  it 'HTML-escapes all YAML keys' do
    content = <<-MD.strip_heredoc
      ---
      <b>foo</b>: 'foo'
      ---
    MD

    output = filter(content)

    expect(output).to match '&lt;b&gt;foo&lt;/b&gt;'
  end

  it 'HTML-escapes all YAML values' do
    content = <<-MD.strip_heredoc
      ---
      foo: <th>foo</th>
      ---
    MD

    output = filter(content)

    expect(output).to match '&lt;th&gt;foo&lt;/th&gt;'
  end

  it 'supports Arrays' do
    content = <<-MD.strip_heredoc
      ---
      foo:
        - bar
        - baz
      ---
    MD

    output = parse(filter(content))

    aggregate_failures do
      expect(output.css('table').length).to eq 3
      expect(output.xpath('.//table/tr[1]/td/table[1]/tr[1]/td[1]').text).to eq 'bar'
    end
  end

  it 'supports Arrays of Hashes' do
    content = <<-MD.strip_heredoc
      ---
      mvps:
        - version: 8.4
          name: Kyungchul Shin
          date: January 22nd, 2016
        - version: 8.3
          name: Greg Smethells
          date: December 22nd, 2015
        - version: 8.2
          name: Cristian Bica
          date: November 22nd, 2015
      ---
    MD

    output = parse(filter(content))

    aggregate_failures do
      expect(output.css('table').length).to eq 4
      expect(output.xpath('.//table/tr[1]/td/table[2]/tr[2]/th[1]').text).to eq 'name'
      expect(output.xpath('.//table/tr[1]/td/table[2]/tr[2]/td[1]').text).to eq 'Greg Smethells'
    end
  end

  context 'on content without frontmatter' do
    it 'returns the content unmodified' do
      content = <<-MD.strip_heredoc
        # This is some Markdown

        It has no YAML frontmatter to parse.
      MD

      expect(filter(content)).to eq content
    end
  end
end
