# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationHelper, type: :helper do
  before do
    create(:blog)
  end

  describe '#pluralize' do
    it 'returns zero form when size is 0' do
      expect(helper.pluralize(0, 'no items', '1 item', '%d items')).to eq('no items')
    end

    it 'returns one form when size is 1' do
      expect(helper.pluralize(1, 'no items', '1 item', '%d items')).to eq('1 item')
    end

    it 'returns many form with size when size > 1' do
      expect(helper.pluralize(5, 'no items', '1 item', '%d items')).to eq('5 items')
    end
  end

  describe '#link_to_permalink' do
    let(:article) { create(:article, title: 'Test', published: true, published_at: 1.day.ago) }

    it 'creates a link to the item' do
      result = helper.link_to_permalink(article, 'Read more')
      expect(result).to include('Read more')
      expect(result).to include('<a')
    end

    it 'includes style class when provided' do
      result = helper.link_to_permalink(article, 'Read', nil, 'custom-class')
      expect(result).to include('class="custom-class"')
    end

    it 'includes nofollow when requested' do
      result = helper.link_to_permalink(article, 'Read', nil, nil, true)
      expect(result).to include('rel="nofollow"')
    end
  end

  describe '#meta_tag' do
    it 'creates a meta tag' do
      result = helper.meta_tag('description', 'Test description')
      expect(result).to eq('<meta name="description" content="Test description">')
    end

    it 'returns nil for blank values' do
      expect(helper.meta_tag('description', '')).to be_nil
    end

    it 'escapes HTML in values' do
      result = helper.meta_tag('test', '<script>alert("xss")</script>')
      expect(result).not_to include('<script>')
    end
  end

  describe '#error_messages_for' do
    it 'returns empty string when object has no errors' do
      article = create(:article)
      assign(:article, article)
      result = helper.error_messages_for(:article)
      expect(result).to eq('')
    end
  end

  describe '#this_blog' do
    it 'returns the default blog' do
      expect(helper.this_blog).to eq(Blog.default)
    end
  end

  describe '#display_date' do
    it 'formats date according to blog settings' do
      date = Time.zone.local(2024, 6, 15, 12, 30)
      result = helper.display_date(date)
      expect(result).to be_a(String)
    end
  end

  describe '#display_time' do
    it 'formats time according to blog settings' do
      time = Time.zone.local(2024, 6, 15, 12, 30)
      result = helper.display_time(time)
      expect(result).to be_a(String)
    end
  end

  describe '#form_remote_tag' do
    it 'returns a form with data-remote attribute' do
      result = helper.form_remote_tag(url: '/test') { 'content' }
      expect(result).to include('data-remote="true"')
    end
  end

  describe '#link_to_function' do
    it 'creates a link with onclick handler' do
      result = helper.link_to_function('Click me', "alert('hello')")
      expect(result).to include('Click me')
      expect(result).to include('onclick')
    end
  end

  describe '#link_to_remote' do
    it 'creates a link with data-remote' do
      result = helper.link_to_remote('Click', url: '/test')
      expect(result).to include('data-remote="true"')
    end
  end

  describe '#avatar_tag' do
    it 'returns empty string when plugin_avatar is blank' do
      expect(helper.avatar_tag(email: 'test@example.com')).to eq('')
    end
  end

  describe '#render_flash' do
    it 'renders flash messages' do
      allow(helper).to receive(:flash).and_return({ notice: 'Success!' })
      result = helper.render_flash
      expect(result).to include('Success!')
    end
  end

  describe '#content_array' do
    it 'returns articles when set' do
      articles = [create(:article)]
      assign(:articles, articles)
      expect(helper.content_array).to eq(articles)
    end

    it 'returns empty array when nothing set' do
      expect(helper.content_array).to eq([])
    end
  end

  describe '#display_date_and_time' do
    it 'formats date and time' do
      time = Time.zone.local(2024, 6, 15, 12, 30)
      result = helper.display_date_and_time(time)
      expect(result).to be_a(String)
    end
  end

  describe '#comments_link' do
    let(:article) { create(:article, title: 'Test', published: true, published_at: 1.day.ago) }

    it 'returns link with comment count' do
      result = helper.comments_link(article)
      expect(result).to include('comments')
    end
  end

  describe '#trackbacks_link' do
    let(:article) { create(:article, title: 'Test', published: true, published_at: 1.day.ago) }

    it 'returns link with trackback count' do
      result = helper.trackbacks_link(article)
      expect(result).to include('trackback')
    end
  end

  describe '#date' do
    it 'returns formatted date span' do
      time = Time.zone.local(2024, 6, 15, 12, 30)
      result = helper.date(time)
      expect(result).to include('typo_date')
    end
  end

  describe '#toggle_effect' do
    it 'returns JavaScript toggle code' do
      result = helper.toggle_effect('element_id', 'Effect.SlideUp', '', 'Effect.SlideDown', '')
      expect(result).to include('element_id')
    end
  end

  describe '#feed_title' do
    it 'returns blog name when no page title' do
      result = helper.feed_title
      expect(result).to eq(Blog.default.blog_name)
    end

    it 'returns feed_title when set' do
      assign(:feed_title, 'Custom Feed Title')
      expect(helper.feed_title).to eq('Custom Feed Title')
    end
  end

  describe '#author_link' do
    let(:user) { create(:user, email: 'author@example.com', name: 'John Author') }
    let(:article) { create(:article, user: user) }

    it 'returns author name' do
      result = helper.author_link(article)
      expect(result).to include('John Author')
    end
  end

  describe '#submit_to_remote' do
    it 'creates a remote submit button' do
      result = helper.submit_to_remote('commit', 'Save', url: '/test')
      expect(result).to include('data-remote')
    end
  end

  describe '#remote_function' do
    it 'returns JavaScript for remote request' do
      result = helper.remote_function(url: '/test', method: :post)
      expect(result).to include('/test')
      expect(result).to include('data-remote')
    end
  end

  describe '#ckeditor_textarea' do
    it 'returns empty string' do
      result = helper.ckeditor_textarea(:article, :body)
      expect(result).to eq('')
    end
  end

  describe '#markup_help_popup' do
    it 'returns empty string when no markup' do
      result = helper.markup_help_popup(nil, 'Help')
      expect(result).to eq('')
    end
  end

  describe '#render_the_flash' do
    it 'returns nil when no flash messages' do
      allow(helper).to receive(:flash).and_return({})
      expect(helper.render_the_flash).to be_nil
    end

    it 'renders error flash' do
      allow(helper).to receive(:flash).and_return({ error: 'Something went wrong' })
      result = helper.render_the_flash
      expect(result).to include('error')
    end
  end

  describe '#new_js_distance_of_time_in_words_to_now' do
    it 'returns span with timestamp' do
      time = Time.zone.local(2024, 6, 15, 12, 30)
      result = helper.new_js_distance_of_time_in_words_to_now(time)
      expect(result).to include('gmttimestamp')
    end
  end

  describe '#show_meta_keyword' do
    before do
      Blog.default.update(use_meta_keyword: true)
    end

    it 'returns nil when keywords blank' do
      assign(:keywords, nil)
      expect(helper.show_meta_keyword).to be_nil
    end

    it 'returns meta tag when keywords present' do
      assign(:keywords, 'ruby, rails')
      result = helper.show_meta_keyword
      expect(result).to include('keywords')
    end
  end

  describe '#use_canonical' do
    it 'returns nil when canonical_url not set' do
      expect(helper.use_canonical).to be_nil
    end

    it 'returns link tag when canonical_url set' do
      assign(:canonical_url, 'http://example.com/article')
      result = helper.use_canonical
      expect(result).to include('canonical')
    end
  end

  describe '#show_menu_for_post_type' do
    it 'returns nil when no articles of type exist' do
      result = helper.show_menu_for_post_type('special')
      expect(result).to be_nil
    end
  end
end
