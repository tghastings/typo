# frozen_string_literal: true

require 'test_helper'

class TypoTextfilterBibliographyTest < ActiveSupport::TestCase
  def setup
    @blog = Blog.first || Blog.create!(blog_name: 'Test Blog', base_url: 'http://test.com')
  end

  test 'plugin is registered' do
    assert TextFilterPlugin.available_filters.include?(TypoTextfilterBibliography)
  end

  test 'plugin has correct attributes' do
    assert_equal 'Bibliography', TypoTextfilterBibliography.display_name
    assert_equal 'bibliography', TypoTextfilterBibliography.filter_name
  end

  test 'adds superscript numbers to links' do
    html = '<p>Check out <a href="https://google.com">Google</a> for search.</p>'
    result = TypoTextfilterBibliography.filtertext(html)

    assert_match /<a href="https:\/\/google.com">Google<\/a><sup class="bibliography-ref">\[1\]<\/sup>/, result
  end

  test 'numbers multiple links sequentially' do
    html = '<p>Visit <a href="https://google.com">Google</a> and <a href="https://github.com">GitHub</a>.</p>'
    result = TypoTextfilterBibliography.filtertext(html)

    assert_match /Google<\/a><sup class="bibliography-ref">\[1\]<\/sup>/, result
    assert_match /GitHub<\/a><sup class="bibliography-ref">\[2\]<\/sup>/, result
  end

  test 'creates bibliography section at bottom' do
    html = '<p>Check out <a href="https://google.com">Google</a>.</p>'
    result = TypoTextfilterBibliography.filtertext(html)

    assert_match /<div class="bibliography">/, result
    assert_match /<h4>References<\/h4>/, result
    assert_match /\[1\].*google\.com/, result
  end

  test 'shows domain name in bibliography' do
    html = '<p>Visit <a href="https://www.example.com/path/to/page">Example</a>.</p>'
    result = TypoTextfilterBibliography.filtertext(html)

    assert_match /example\.com/, result
  end

  test 'handles links without href gracefully' do
    html = '<p>An <a name="anchor">anchor</a> tag.</p>'
    result = TypoTextfilterBibliography.filtertext(html)

    # Should not add reference to anchor-only links
    refute_match /\[1\]/, result
  end

  test 'skips internal anchor links' do
    html = '<p>Jump to <a href="#section">section</a>.</p>'
    result = TypoTextfilterBibliography.filtertext(html)

    refute_match /bibliography-ref/, result
  end

  test 'handles empty content' do
    result = TypoTextfilterBibliography.filtertext('')
    assert_equal '', result
  end

  test 'handles content with no links' do
    html = '<p>Just some text without links.</p>'
    result = TypoTextfilterBibliography.filtertext(html)

    assert_equal html, result
    refute_match /bibliography/, result
  end

  test 'deduplicates same URLs' do
    html = '<p>Visit <a href="https://google.com">Google</a> and later <a href="https://google.com">Google again</a>.</p>'
    result = TypoTextfilterBibliography.filtertext(html)

    # Both should reference [1]
    assert_match /Google<\/a><sup class="bibliography-ref">\[1\]<\/sup>/, result
    assert_match /Google again<\/a><sup class="bibliography-ref">\[1\]<\/sup>/, result

    # Only one entry in bibliography
    assert_equal 1, result.scan(/\[1\]/).count - 2  # Subtract the two inline refs
  end

  test 'bibliography links are clickable' do
    html = '<p>Check <a href="https://example.com/page">this</a>.</p>'
    result = TypoTextfilterBibliography.filtertext(html)

    # The bibliography entry should have a clickable link
    assert_match /<a href="https:\/\/example\.com\/page"[^>]*>example\.com<\/a>/, result
  end
end
