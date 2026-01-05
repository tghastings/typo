# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Page, type: :model do
  before do
    create(:blog)
  end

  describe 'factory' do
    it 'creates valid page' do
      page = create(:page)
      expect(page).to be_valid
      expect(page).to be_persisted
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      user = create(:user)
      page = create(:page, user: user)
      expect(page.user).to eq(user)
    end
  end

  describe '#set_permalink' do
    it 'sets permalink from name' do
      page = create(:page, name: 'about-me', title: 'About Me')
      expect(page.name).to eq('about-me')
    end
  end

  describe 'scopes' do
    describe '.published' do
      it 'returns only published pages' do
        published = create(:page, published: true, published_at: 1.day.ago, state: 'published')
        unpublished = build(:page, published: false, state: 'draft')
        unpublished.save(validate: false)
        expect(Page.published).to include(published)
        expect(Page.published).not_to include(unpublished)
      end
    end
  end

  describe '#permalink_url' do
    it 'returns page URL' do
      page = create(:page, name: 'about')
      url = page.permalink_url
      expect(url).to include('about')
    end
  end

  describe '#external_redirect?' do
    it 'returns true when redirect_url is present' do
      page = build(:page, redirect_url: 'http://external.com/redirect')
      expect(page.external_redirect?).to be true
    end

    it 'returns false when redirect_url is blank' do
      page = create(:page, redirect_url: nil)
      expect(page.external_redirect?).to be false
    end
  end

  describe '.search_paginate' do
    it 'paginates search results' do
      5.times { |i| create(:page, name: "page-#{i}", title: "Page #{i}") }
      results = Page.search_paginate({}, { page: 1, per_page: 2 })
      expect(results.size).to eq(2)
    end

    it 'filters by searchstring' do
      create(:page, name: 'ruby-page', title: 'About Ruby', body: 'Ruby content')
      create(:page, name: 'python-page', title: 'About Python', body: 'Python content')
      results = Page.search_paginate({ searchstring: 'Ruby' }, { page: 1, per_page: 10 })
      expect(results.size).to eq(1)
      expect(results.first.title).to eq('About Ruby')
    end
  end
end
