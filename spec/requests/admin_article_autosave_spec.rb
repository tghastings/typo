require 'spec_helper'

RSpec.describe "Admin Article Autosave", type: :request do
  let!(:blog) { FactoryBot.create(:blog) }
  let!(:admin_profile) { Profile.find_by(label: 'admin') || FactoryBot.create(:profile_admin) }
  let!(:admin_user) { FactoryBot.create(:user, profile: admin_profile, login: 'admin_user', password: 'test123') }
  let!(:text_filter) { FactoryBot.create(:textile) }

  before do
    # Login as admin
    post '/accounts/login', params: { user: { login: 'admin_user', password: 'test123' } }
    follow_redirect!
  end

  describe "POST /admin/content/autosave with Turbo Stream" do
    it "creates a new draft article and returns Turbo Stream response" do
      expect {
        post '/admin/content/autosave',
          params: {
            article: {
              title: 'Autosaved Article',
              body_and_extended: 'Content being autosaved',
              text_filter: text_filter.id
            }
          },
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      }.to change { Article.count }.by(1)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('turbo-stream')

      article = Article.last
      expect(article.title).to eq('Autosaved Article')
      expect(article.body).to eq('Content being autosaved')
      expect(article.state.to_s.downcase).to eq('draft')
      expect(article.parent_id).to be_nil
    end

    it "updates existing draft on subsequent autosaves" do
      # Create initial draft
      post '/admin/content/autosave',
        params: {
          article: {
            title: 'First Save',
            body_and_extended: 'Initial content'
          }
        },
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      first_article = Article.last
      first_article_id = first_article.id

      # Autosave again with same article ID
      expect {
        post '/admin/content/autosave',
          params: {
            article: {
              id: first_article_id,
              title: 'Second Save',
              body_and_extended: 'Updated content'
            }
          },
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      }.not_to change { Article.count }

      first_article.reload
      expect(first_article.title).to eq('Second Save')
      expect(first_article.body).to eq('Updated content')
    end

    it "creates draft for published article" do
      published_article = FactoryBot.create(:article,
        user: admin_user,
        state: 'published',
        title: 'Published Article',
        published: true
      )

      expect {
        post '/admin/content/autosave',
          params: {
            article: {
              id: published_article.id,
              title: 'Edited Title',
              body_and_extended: 'Edited content'
            }
          },
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      }.to change { Article.count }.by(1)

      draft = Article.last
      expect(draft.parent_id).to eq(published_article.id)
      expect(draft.state.to_s.downcase).to eq('draft')
      expect(draft.title).to eq('Edited Title')
    end
  end

  describe "POST /admin/content/autosave with HTML (backwards compatibility)" do
    it "accepts HTML format requests for test compatibility" do
      expect {
        post '/admin/content/autosave',
          params: {
            article: {
              title: 'Test Article',
              body_and_extended: 'Test content'
            }
          }
      }.to change { Article.count }.by(1)

      expect(response).to have_http_status(:success)
    end
  end
end
