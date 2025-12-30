# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Profiles', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  describe 'GET /admin/profiles' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/profiles'
        expect(response).to redirect_to(controller: '/accounts', action: 'login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'renders the profile page' do
        get '/admin/profiles'
        expect(response).to be_successful
      end

      it 'displays user profile information' do
        get '/admin/profiles'
        expect(response.body).to include(@admin.login)
      end
    end
  end

  describe 'POST /admin/profiles' do
    before { login_admin }

    context 'with valid parameters' do
      it 'updates the user profile' do
        post '/admin/profiles', params: {
          user: { firstname: 'John', lastname: 'Doe', email: 'newemail@test.com' }
        }
        @admin.reload
        expect(@admin.email).to eq('newemail@test.com')
        expect(@admin.firstname).to eq('John')
        expect(@admin.lastname).to eq('Doe')
      end

      it 'sets success flash message' do
        post '/admin/profiles', params: {
          user: { name: 'Updated Name' }
        }
        expect(flash[:notice]).to include('successfully updated')
      end

      it 'updates notification settings' do
        post '/admin/profiles', params: {
          user: { notify_via_email: true, notify_on_comments: true }
        }
        @admin.reload
        expect(@admin.notify_via_email).to be_truthy
      end
    end

    context 'with password change' do
      it 'changes password when confirmation matches' do
        old_password = @admin.password
        post '/admin/profiles', params: {
          user: { password: 'newpassword123', password_confirmation: 'newpassword123' }
        }
        expect(@admin.reload.password).not_to eq(old_password)
      end
    end
  end
end
