# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TextFilter, type: :model do
  before do
    create(:blog)
  end

  describe '.available_filters' do
    it 'returns list of available filters' do
      result = TextFilter.available_filters
      expect(result).to be_an(Array)
    end
  end

  describe '.macro_filters' do
    it 'returns available macro filters' do
      result = TextFilter.macro_filters
      expect(result).to be_an(Array)
    end
  end

  describe '.filter_text_by_name' do
    it 'filters text using the named filter' do
      create(:markdown)
      blog = Blog.first
      result = TextFilter.filter_text_by_name(blog, '**bold**', 'markdown')
      expect(result).to be_a(String)
    end
  end

  describe '#to_text_filter' do
    it 'returns self' do
      filter = create(:markdown)
      expect(filter.to_text_filter).to eq(filter)
    end
  end

  describe '#commenthelp' do
    it 'returns comment help text' do
      filter = create(:markdown_smartypants)
      expect(filter.commenthelp).to be_a(String)
    end
  end

  describe '#to_s' do
    it 'returns the filter name' do
      filter = create(:markdown)
      expect(filter.to_s).to eq('markdown')
    end
  end
end
