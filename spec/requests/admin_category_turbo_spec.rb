require 'spec_helper'

RSpec.describe "Admin Category Management with Turbo", type: :request do
  let!(:blog) { FactoryBot.create(:blog) }
  let!(:admin_profile) { Profile.find_by(label: 'admin') || FactoryBot.create(:profile_admin) }
  let!(:admin_user) { FactoryBot.create(:user, profile: admin_profile, login: 'admin_user', password: 'test123') }
  let!(:existing_category) { FactoryBot.create(:category, name: 'Existing Category') }

  before do
    # Login as admin
    post '/accounts/login', params: { user: { login: 'admin_user', password: 'test123' } }
    follow_redirect!
  end

  describe "GET /admin/categories/new with Turbo Stream" do
    it "returns overlay form with Turbo Stream" do
      get '/admin/categories/new',
        headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('turbo-stream')
      expect(response.body).to include('turbo-stream')
      expect(response.body).to include('category_overlay_container')
    end
  end

  describe "POST /admin/categories/edit with Turbo Stream (creating new category)" do
    it "creates a new category and returns Turbo Stream to update list and close overlay" do
      expect {
        post "/admin/categories/edit/#{Category.new.id}",
          params: {
            category: {
              name: 'New Category',
              description: 'Category description',
              keywords: 'test, category'
            }
          },
          headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      }.to change { Category.count }.by(1)

      expect(response).to have_http_status(:success)
      expect(response.content_type).to include('turbo-stream')

      new_category = Category.last
      expect(new_category.name).to eq('New Category')
      expect(new_category.description).to eq('Category description')

      # Should have turbo streams to replace categories list and remove overlay
      expect(response.body).to include('turbo-stream')
      expect(response.body).to include('categories')
      expect(response.body).to include('category_overlay')
    end
  end

  describe "POST /admin/categories/edit with HTML (backwards compatibility)" do
    it "creates category with HTML format" do
      expect {
        post "/admin/categories/edit/#{existing_category.id}",
          params: {
            category: {
              name: 'Updated Category',
              description: 'Updated description'
            }
          }
      }.to change { existing_category.reload.name }.to('Updated Category')

      expect(response).to have_http_status(:redirect)
    end
  end
end
