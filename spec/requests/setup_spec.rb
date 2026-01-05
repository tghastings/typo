# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setup', type: :request do
  describe 'GET /setup' do
    context 'when blog is already configured' do
      before do
        create(:blog)
      end

      it 'redirects to articles index' do
        get '/setup'
        expect(response).to redirect_to('/')
      end
    end

    context 'when blog is not configured' do
      before do
        Blog.destroy_all
      end

      it 'displays setup form' do
        get '/setup'
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /setup' do
    before do
      Blog.destroy_all
      User.destroy_all
    end

    context 'with valid params' do
      let(:valid_params) do
        {
          setting: {
            blog_name: 'My New Blog',
            email: 'admin@example.com'
          }
        }
      end

      it 'creates blog' do
        expect {
          post '/setup', params: valid_params
        }.to change(Blog, :count).by(1)
      end

      it 'creates admin user' do
        expect {
          post '/setup', params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'redirects to confirm' do
        post '/setup', params: valid_params
        expect(response).to redirect_to(action: 'confirm')
      end
    end

    context 'with invalid params' do
      it 'handles missing blog name' do
        post '/setup', params: { setting: { blog_name: '', email: 'test@test.com' } }
        expect(response.status).to be_in([200, 302])
      end

      it 'handles missing email' do
        post '/setup', params: { setting: { blog_name: 'Test', email: '' } }
        expect(response.status).to be_in([200, 302])
      end
    end
  end
end
