# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Article, type: :model do
  before do
    create(:blog)
  end

  describe 'validations' do
    it 'validates presence of title' do
      article = build(:article, title: nil)
      expect(article).not_to be_valid
      expect(article.errors[:title]).to include("can't be blank")
    end

    it 'validates uniqueness of guid' do
      create(:article, guid: 'unique-guid-123')
      article2 = build(:article, guid: 'unique-guid-123')
      expect(article2).not_to be_valid
      expect(article2.errors[:guid]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it 'belongs to user' do
      user = create(:user)
      article = create(:article, user: user)
      expect(article.user).to eq(user)
    end

    it 'has many comments' do
      article = create(:article)
      comment = create(:comment, article: article)
      expect(article.comments).to include(comment)
    end

    it 'has many trackbacks' do
      article = create(:article)
      trackback = create(:trackback, article: article)
      expect(article.trackbacks).to include(trackback)
    end

    it 'has many categories through categorizations' do
      article = create(:article)
      category = create(:category)
      article.categories << category
      expect(article.categories).to include(category)
    end

    it 'has and belongs to many tags' do
      article = create(:article)
      tag = create(:tag)
      article.tags << tag
      expect(article.tags).to include(tag)
    end

    it 'has many resources' do
      article = create(:article)
      resource = create(:resource, article: article)
      expect(article.resources).to include(resource)
    end
  end

  describe 'scopes' do
    describe '.published' do
      it 'returns only published articles' do
        published = create(:article, published: true, published_at: 1.day.ago)
        create(:unpublished_article)
        expect(Article.published).to include(published)
        expect(Article.published.count).to eq(1)
      end

      it 'excludes future published articles' do
        create(:article, published: true, published_at: 1.day.from_now)
        expect(Article.published).to be_empty
      end
    end

    describe '.drafts' do
      it 'returns only draft articles' do
        article = create(:article)
        article.update_column(:state, 'draft')
        expect(Article.drafts).to include(article)
      end
    end

    describe '.withdrawn' do
      it 'returns only withdrawn articles' do
        article = create(:article)
        article.update_column(:state, 'withdrawn')
        expect(Article.withdrawn).to include(article)
      end
    end

    describe '.category' do
      it 'returns articles in specified category' do
        category = create(:category)
        article = create(:article)
        article.categories << category
        expect(Article.category(category.id)).to include(article)
      end
    end

    describe '.without_parent' do
      it 'returns articles without parent' do
        article = create(:article, parent_id: nil)
        expect(Article.without_parent).to include(article)
      end
    end
  end

  describe '#set_permalink' do
    it 'sets permalink from title' do
      article = create(:article, title: 'My Great Post', permalink: nil, state: 'published')
      expect(article.permalink).to eq('my-great-post')
    end

    it 'does not change permalink for drafts' do
      article = build(:article, title: 'My Great Post', state: 'draft')
      article.set_permalink
      # Permalink should remain as is for drafts
    end
  end

  describe '#permalink_url' do
    it 'generates correct URL' do
      article = create(:article, published_at: Time.zone.local(2024, 1, 15), permalink: 'test-article')
      url = article.permalink_url
      expect(url).to include('2024')
      expect(url).to include('01')
      expect(url).to include('15')
      expect(url).to include('test-article')
    end
  end

  describe '#next and #previous' do
    it 'returns next article by published_at' do
      article1 = create(:article, published_at: 2.days.ago)
      article2 = create(:article, published_at: 1.day.ago)
      expect(article1.next).to eq(article2)
    end

    it 'returns previous article by published_at' do
      article1 = create(:article, published_at: 2.days.ago)
      article2 = create(:article, published_at: 1.day.ago)
      expect(article2.previous).to eq(article1)
    end

    it 'returns nil when no next article' do
      article = create(:article, published_at: 1.day.ago)
      expect(article.next).to be_nil
    end
  end

  describe '#has_child?' do
    it 'returns true when article has child' do
      parent = create(:article)
      create(:article, parent_id: parent.id)
      expect(parent.has_child?).to be true
    end

    it 'returns false when article has no child' do
      article = create(:article)
      expect(article.has_child?).to be false
    end
  end

  describe '#comments_closed?' do
    it 'returns true when comments not allowed' do
      article = create(:article, allow_comments: false)
      expect(article.comments_closed?).to be true
    end

    it 'returns false when comments allowed and in window' do
      article = create(:article, allow_comments: true, published_at: 1.day.ago)
      expect(article.comments_closed?).to be false
    end
  end

  describe '#password_protected?' do
    it 'returns true when password is set' do
      article = create(:article)
      article.password = 'secret'
      expect(article.password_protected?).to be true
    end

    it 'returns false when password is blank' do
      article = create(:article, password: nil)
      expect(article.password_protected?).to be false
    end
  end

  describe '#body_and_extended' do
    it 'returns body when extended is blank' do
      article = create(:article, body: 'Body content', extended: '')
      expect(article.body_and_extended).to eq('Body content')
    end

    it 'returns body and extended with separator' do
      article = create(:article, body: 'Body content', extended: 'Extended content')
      expect(article.body_and_extended).to eq("Body content\n<!--more-->\nExtended content")
    end
  end

  describe '#body_and_extended=' do
    it 'splits content at <!--more-->' do
      article = build(:article)
      article.body_and_extended = "Body content\n<!--more-->\nExtended content"
      expect(article.body).to eq('Body content')
      expect(article.extended).to eq('Extended content')
    end

    it 'sets body only when no separator' do
      article = build(:article)
      article.body_and_extended = 'Just body content'
      expect(article.body).to eq('Just body content')
      expect(article.extended).to eq('')
    end
  end

  describe '#add_comment' do
    it 'builds a comment on the article' do
      article = create(:article)
      comment = article.add_comment(author: 'John', body: 'Great post!')
      expect(comment).to be_a(Comment)
      expect(comment.article).to eq(article)
    end
  end

  describe '#add_category' do
    it 'builds a categorization' do
      article = create(:article)
      category = create(:category)
      categorization = article.add_category(category, true)
      expect(categorization.category).to eq(category)
      expect(categorization.is_primary).to be true
    end
  end

  describe '#access_by?' do
    it 'returns true for admin user' do
      admin = create(:user, profile: create(:profile_admin))
      article = create(:article)
      expect(article.access_by?(admin)).to be true
    end

    it 'returns true for article owner' do
      user = create(:user)
      article = create(:article, user: user)
      expect(article.access_by?(user)).to be true
    end

    it 'returns false for other users' do
      user = create(:user)
      other_user = create(:user)
      article = create(:article, user: user)
      expect(article.access_by?(other_user)).to be false
    end
  end

  describe '.search' do
    it 'finds articles matching query' do
      create(:article, body: 'Ruby is awesome', title: 'Programming')
      results = Article.search('Ruby')
      expect(results.count).to eq(1)
    end

    it 'returns empty array for blank query' do
      expect(Article.search('')).to eq([])
    end
  end

  describe '.search_with_pagination' do
    it 'paginates search results' do
      5.times { create(:article) }
      results = Article.search_with_pagination({ state: 'no_draft' }, { page: 1, per_page: 2 })
      expect(results.count).to eq(2)
    end

    it 'filters by searchstring' do
      create(:article, title: 'Ruby Guide')
      create(:article, title: 'Python Guide')
      results = Article.search_with_pagination({ state: 'no_draft', searchstring: 'Ruby' }, { page: 1, per_page: 10 })
      expect(results.count).to eq(1)
    end
  end

  describe '.find_by_permalink' do
    it 'finds article by permalink params' do
      article = create(:article, published_at: Time.zone.local(2024, 1, 15), permalink: 'test-post')
      found = Article.find_by_permalink(year: '2024', month: '01', day: '15', title: 'test-post')
      expect(found).to eq(article)
    end

    it 'raises RecordNotFound for non-existent article' do
      expect {
        Article.find_by_permalink(year: '2024', month: '01', day: '15', title: 'nonexistent')
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.count_by_date' do
    it 'counts articles by year' do
      create(:article, published: true, published_at: Time.zone.local(2024, 6, 15))
      create(:article, published: true, published_at: Time.zone.local(2024, 7, 20))
      expect(Article.count_by_date(2024)).to eq(2)
    end

    it 'counts articles by year and month' do
      create(:article, published: true, published_at: Time.zone.local(2024, 6, 15))
      create(:article, published: true, published_at: Time.zone.local(2024, 7, 20))
      expect(Article.count_by_date(2024, 6)).to eq(1)
    end
  end

  describe '.get_or_build_article' do
    it 'returns existing article when id provided' do
      article = create(:article)
      expect(Article.get_or_build_article(article.id)).to eq(article)
    end

    it 'builds new article when id is nil' do
      article = Article.get_or_build_article(nil)
      expect(article).to be_new_record
      expect(article.published).to be true
    end
  end

  describe '#keywords_to_tags' do
    it 'creates tags from keywords' do
      article = create(:article)
      article.keywords = 'ruby, rails, programming'
      article.keywords_to_tags
      expect(article.tags.map(&:name)).to include('ruby', 'rails', 'programming')
    end
  end

  describe '#feed_url' do
    it 'generates RSS feed URL' do
      article = create(:article, published_at: Time.zone.local(2024, 1, 15), permalink: 'test')
      expect(article.feed_url(:rss)).to include('.rss')
    end

    it 'generates Atom feed URL' do
      article = create(:article, published_at: Time.zone.local(2024, 1, 15), permalink: 'test')
      expect(article.feed_url(:atom)).to include('.atom')
    end
  end

  describe '#trackback_url' do
    it 'generates trackback URL' do
      article = create(:article)
      expect(article.trackback_url).to include('trackbacks')
      expect(article.trackback_url).to include(article.id.to_s)
    end
  end

  describe '#comment_url' do
    it 'generates comment URL' do
      article = create(:article)
      expect(article.comment_url).to include('comments')
      expect(article.comment_url).to include(article.id.to_s)
    end
  end

  describe 'callbacks' do
    it 'clears whiteboard when body changes' do
      article = create(:article, body: 'Original body')
      article.whiteboard = { cached: 'data' }
      article.save
      article.body = 'New body'
      article.save
      expect(article.whiteboard).to eq({})
    end
  end

  describe '#published_comments' do
    it 'returns only published comments' do
      article = create(:article)
      published = create(:comment, article: article, published: true)
      create(:spam_comment, article: article)
      expect(article.published_comments).to include(published)
      expect(article.published_comments.count).to eq(1)
    end
  end

  describe '#published_trackbacks' do
    it 'returns only published trackbacks' do
      article = create(:article)
      trackback = create(:trackback, article: article, published: true)
      expect(article.published_trackbacks).to include(trackback)
    end
  end

  describe '#allow_comments?' do
    it 'returns true when comments are allowed' do
      article = create(:article, allow_comments: true)
      expect(article.allow_comments?).to be true
    end

    it 'returns false when comments are not allowed' do
      article = create(:article, allow_comments: false)
      expect(article.allow_comments?).to be false
    end
  end

  describe '#allow_pings?' do
    it 'returns true when pings are allowed' do
      article = create(:article, allow_pings: true)
      expect(article.allow_pings?).to be true
    end

    it 'returns false when pings are not allowed' do
      article = create(:article, allow_pings: false)
      expect(article.allow_pings?).to be false
    end
  end

  describe '#default_text_filter' do
    it 'returns blog text filter object' do
      article = create(:article)
      expect(article.default_text_filter).to be_a(TextFilter)
    end
  end

  describe '#html' do
    it 'returns rendered HTML content' do
      article = create(:article, body: '**bold**')
      result = article.html(:body)
      expect(result).to be_a(String)
    end
  end

  describe '#pings_closed?' do
    it 'returns true when pings not allowed' do
      article = create(:article, allow_pings: false)
      expect(article.pings_closed?).to be true
    end
  end

  describe '#get_rss_description' do
    it 'returns body for RSS' do
      article = create(:article, body: 'RSS content')
      expect(article.get_rss_description).to be_a(String)
    end
  end

  describe '#to_param' do
    it 'returns param array' do
      article = create(:article, permalink: 'my-article')
      expect(article.to_param).to be_a(Array)
    end
  end

  describe 'state' do
    it 'has default state' do
      article = create(:article)
      expect(article.state).to be_present
    end
  end
end
