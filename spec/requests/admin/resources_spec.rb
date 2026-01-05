# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Resources', type: :request do
  let!(:blog) { create(:blog) }
  let!(:admin_profile) { Profile.find_by(label: 'admin') || create(:profile_admin) }
  let!(:admin) { create(:user, password: 'password123', profile: admin_profile) }

  def login_as_admin
    post '/accounts/login', params: { user: { login: admin.login, password: 'password123' } }
  end

  describe 'GET /admin/resources' do
    before { login_as_admin }

    it 'returns success' do
      get '/admin/resources'
      expect(response).to have_http_status(:success)
    end

    it 'displays resources page' do
      get '/admin/resources'
      expect(response.body.downcase).to include('resource').or include('file').or include('upload')
    end

    context 'with existing resources' do
      before do
        create(:resource, filename: 'test-image.jpg', mime: 'image/jpeg')
      end

      it 'lists resources' do
        get '/admin/resources'
        expect(response.body).to include('test-image.jpg')
      end
    end

    context 'with pagination' do
      it 'handles page param' do
        get '/admin/resources', params: { page: 1 }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe 'POST /admin/resources/upload' do
    before { login_as_admin }

    context 'with valid file' do
      let(:file) { Rack::Test::UploadedFile.new(StringIO.new('test content'), 'text/plain', original_filename: 'testfile.txt') }

      it 'uploads file successfully' do
        expect {
          post '/admin/resources/upload', params: { upload: { filename: file } }
        }.to change(Resource, :count).by(1)
      end

      it 'redirects to index' do
        post '/admin/resources/upload', params: { upload: { filename: file } }
        expect(response).to redirect_to(action: 'index')
      end

      it 'sets flash notice' do
        post '/admin/resources/upload', params: { upload: { filename: file } }
        expect(flash[:notice]).to include('uploaded')
      end
    end

    context 'without file' do
      it 'shows error' do
        post '/admin/resources/upload', params: { upload: {} }
        expect(flash[:error]).to be_present
      end

      it 'redirects to index' do
        post '/admin/resources/upload', params: { upload: {} }
        expect(response).to redirect_to(action: 'index')
      end
    end

    context 'when upload fails' do
      it 'returns error for invalid upload' do
        post '/admin/resources/upload', params: { upload: { filename: 'not a file' } }
        expect(flash[:error]).to be_present
      end
    end
  end

  describe 'POST /admin/resources/update' do
    before { login_as_admin }

    let!(:resource) { create(:resource, filename: 'original.jpg', mime: 'image/jpeg') }

    it 'updates resource metadata' do
      post '/admin/resources/update', params: {
        resource: { id: resource.id, mime: 'image/png' }
      }
      expect(response).to redirect_to(action: 'index')
    end

    it 'sets flash notice on success' do
      post '/admin/resources/update', params: {
        resource: { id: resource.id, mime: 'image/png' }
      }
      expect(flash[:notice]).to be_present
    end
  end

  describe 'GET /admin/resources/get_thumbnails' do
    before { login_as_admin }

    it 'returns thumbnails' do
      get '/admin/resources/get_thumbnails', params: { position: 0 }
      expect(response).to have_http_status(:success)
    end

    it 'handles different positions' do
      get '/admin/resources/get_thumbnails', params: { position: 10 }
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /admin/resources/destroy/:id' do
    before { login_as_admin }

    let!(:resource) { create(:resource, filename: 'delete-me.jpg') }

    it 'shows destroy confirmation' do
      get "/admin/resources/destroy/#{resource.id}"
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /admin/resources/destroy/:id' do
    before { login_as_admin }

    let!(:resource) { create(:resource, filename: 'delete-me.jpg') }

    it 'deletes resource' do
      expect {
        post "/admin/resources/destroy/#{resource.id}"
      }.to change(Resource, :count).by(-1)
    end

    it 'redirects to index' do
      post "/admin/resources/destroy/#{resource.id}"
      expect(response).to redirect_to(action: 'index')
    end

    it 'sets flash notice' do
      post "/admin/resources/destroy/#{resource.id}"
      expect(flash[:notice]).to include('deleted')
    end

    context 'with non-existent resource' do
      it 'handles missing resource gracefully' do
        post '/admin/resources/destroy/99999'
        expect(flash[:error]).to be_present
      end
    end
  end

  describe 'GET /admin/resources/serve/:filename' do
    before { login_as_admin }

    context 'with non-existent resource' do
      it 'returns not found' do
        get '/admin/resources/serve/nonexistent.txt'
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
