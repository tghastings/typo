require 'spec_helper'

RSpec.describe "Admin Feedback with Turbo", type: :request do
  let!(:blog) { FactoryBot.create(:blog) }
  let!(:admin_profile) { Profile.find_by(label: 'admin') || FactoryBot.create(:profile_admin) }
  let!(:admin_user) { FactoryBot.create(:user, profile: admin_profile, login: 'admin_user', password: 'test123') }
  let!(:article) { FactoryBot.create(:article, user: admin_user) }
  let!(:ham_comment) { FactoryBot.create(:comment, article: article, state: 'ham', author: 'Ham Author') }
  let!(:spam_comment) { FactoryBot.create(:comment, article: article, state: 'spam', author: 'Spam Author') }

  before do
    # Login as admin
    post '/accounts/login', params: { user: { login: 'admin_user', password: 'test123' } }
    follow_redirect!
  end

  describe "GET /admin/feedback with Turbo Frame" do
    it "returns feedback list in turbo frame format" do
      get '/admin/feedback', headers: { 'Turbo-Frame' => 'feedback_list' }

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Ham Author')
      expect(response.body).to include('Spam Author')
    end

    it "filters by ham status" do
      get '/admin/feedback', params: { published: 'f' }

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Ham Author')
    end

    it "filters by spam status" do
      get '/admin/feedback', params: { published: 'spam' }

      expect(response).to have_http_status(:success)
      expect(response.body).to include('Spam Author')
    end
  end

  describe "POST /admin/feedback/mark_as_ham with Turbo Stream" do
    it "marks spam comment as ham and returns Turbo Stream" do
      expect(spam_comment.reload.ham?).to be false

      post "/admin/feedback/mark_as_ham/#{spam_comment.id}",
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('turbo-stream')

      expect(spam_comment.reload.ham?).to be true
      expect(response.body).to include('turbo-stream')
      expect(response.body).to include("feedback_#{spam_comment.id}")
    end
  end

  describe "POST /admin/feedback/mark_as_spam with Turbo Stream" do
    it "marks ham comment as spam and returns Turbo Stream" do
      expect(ham_comment.reload.spam?).to be false

      post "/admin/feedback/mark_as_spam/#{ham_comment.id}",
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('turbo-stream')

      expect(ham_comment.reload.spam?).to be true
      expect(response.body).to include('turbo-stream')
      expect(response.body).to include("feedback_#{ham_comment.id}")
    end
  end

  describe "Turbo Stream response format" do
    it "contains replace action for the feedback row" do
      post "/admin/feedback/mark_as_ham/#{spam_comment.id}",
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response.body).to include('<turbo-stream')
      expect(response.body).to include('action="replace"')
      expect(response.body).to include("target=\"feedback_#{spam_comment.id}\"")
    end
  end
end
