# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Profiles', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin_profile) { Profile.find_by(label: 'admin') || create(:profile_admin) }
  let!(:admin) { create(:user, login: 'testadmin', email: 'admin@test.com', password: 'password123', profile: admin_profile) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: admin.login, password: 'password123' } }
  end

  describe 'GET /admin/profiles' do
    context 'when authenticated' do
      before { login_as_admin }

      it 'returns success' do
        get '/admin/profiles'
        expect(response).to have_http_status(:success)
      end

      it 'displays user profile settings' do
        get '/admin/profiles'
        expect(response.body).to include('testadmin')
      end

      it 'renders form with correct action URL' do
        get '/admin/profiles'
        expect(response.body).to include('action="/admin/profiles"')
      end

      it 'does not include user ID in form action' do
        get '/admin/profiles'
        expect(response.body).not_to include("/admin/profiles/index/#{admin.id}")
      end
    end

    context 'when not authenticated' do
      it 'redirects to login' do
        get '/admin/profiles'
        expect(response).to redirect_to('/accounts/login')
      end
    end
  end

  describe 'POST /admin/profiles' do
    context 'when authenticated' do
      before { login_as_admin }

      it 'updates user name' do
        post '/admin/profiles', params: { user: { name: 'Updated Admin Name' } }
        expect(admin.reload.name).to eq('Updated Admin Name')
      end

      it 'updates user email' do
        post '/admin/profiles', params: { user: { email: 'newemail@test.com' } }
        expect(admin.reload.email).to eq('newemail@test.com')
      end

      it 'updates multiple fields at once' do
        post '/admin/profiles', params: {
          user: {
            firstname: 'John',
            lastname: 'Doe',
            nickname: 'johnd',
            description: 'A test user'
          }
        }
        admin.reload
        expect(admin.firstname).to eq('John')
        expect(admin.lastname).to eq('Doe')
        expect(admin.nickname).to eq('johnd')
        expect(admin.description).to eq('A test user')
      end

      it 'updates password when provided' do
        post '/admin/profiles', params: { user: { password: 'newpassword456' } }
        expect(User.authenticate('testadmin', 'newpassword456')).to eq(admin)
      end

      it 'displays success flash message' do
        post '/admin/profiles', params: { user: { name: 'New Name' } }
        expect(flash[:notice]).to include('successfully updated')
      end

      it 'updates notification preferences' do
        post '/admin/profiles', params: {
          user: {
            notify_via_email: true,
            notify_on_new_articles: true,
            notify_on_comments: true
          }
        }
        admin.reload
        expect(admin.notify_via_email).to be_truthy
        expect(admin.notify_on_new_articles).to be_truthy
        expect(admin.notify_on_comments).to be_truthy
      end

      it 'updates social media fields' do
        post '/admin/profiles', params: {
          user: {
            twitter: '@testuser',
            url: 'https://example.com'
          }
        }
        admin.reload
        expect(admin.twitter).to eq('@testuser')
        expect(admin.url).to eq('https://example.com')
      end
    end

    context 'when not authenticated' do
      it 'redirects to login' do
        post '/admin/profiles', params: { user: { name: 'Hacker' } }
        expect(response).to redirect_to('/accounts/login')
      end

      it 'does not update the user' do
        original_name = admin.name
        post '/admin/profiles', params: { user: { name: 'Hacker' } }
        expect(admin.reload.name).to eq(original_name)
      end
    end
  end
end
