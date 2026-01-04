# frozen_string_literal: true

require 'spec_helper'

describe Admin::ResourcesController do
  render_views

  let(:admin_user) do
    Profile.delete_all
    Factory(:user, login: 'henri', profile: Factory(:profile_admin, label: Profile::ADMIN))
  end

  before do
    Factory(:blog)
    @request.session = { user_id: admin_user.id }
  end

  describe 'GET #index' do
    it 'renders index template' do
      get :index
      expect(response).to be_successful
      expect(response).to render_template('index')
    end

    it 'assigns resources' do
      resource = Factory(:resource)
      get :index
      expect(assigns(:resources)).to include(resource)
    end

    it 'paginates resources' do
      get :index
      expect(assigns(:resources)).not_to be_nil
    end
  end

  describe 'POST #upload' do
    context 'with valid file using upload[filename] parameter' do
      let(:file) { fixture_file_upload('testfile.txt', 'text/plain') }

      before do
        FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
        File.write(Rails.root.join('spec/fixtures/files/testfile.txt'), 'test content')
      end

      after do
        FileUtils.rm_rf(Rails.root.join('spec/fixtures/files'))
      end

      it 'creates a new resource' do
        expect do
          post :upload, upload: { filename: file }
        end.to change(Resource, :count).by(1)
      end

      it 'attaches the file to the resource' do
        post :upload, upload: { filename: file }
        resource = Resource.last
        expect(resource.file).to be_attached
      end

      it 'sets the correct mime type' do
        post :upload, upload: { filename: file }
        resource = Resource.last
        expect(resource.mime).to eq('text/plain')
      end

      it 'sets the original filename' do
        post :upload, upload: { filename: file }
        resource = Resource.last
        expect(resource.filename).to eq('testfile.txt')
      end

      it 'redirects to index' do
        post :upload, upload: { filename: file }
        expect(response).to redirect_to(action: 'index')
      end

      it 'sets success flash message' do
        post :upload, upload: { filename: file }
        expect(flash[:notice]).to include('File uploaded successfully')
      end
    end

    context 'with valid file using file parameter' do
      before do
        FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
        File.write(Rails.root.join('spec/fixtures/files/testfile.txt'), 'test content')
      end

      after do
        FileUtils.rm_rf(Rails.root.join('spec/fixtures/files'))
      end

      let(:file) { fixture_file_upload('testfile.txt', 'text/plain') }

      it 'creates a new resource' do
        expect do
          post :upload, file: file
        end.to change(Resource, :count).by(1)
      end

      it 'attaches the file' do
        post :upload, file: file
        resource = Resource.last
        expect(resource.file).to be_attached
      end
    end

    context 'with no file' do
      it 'does not create a resource' do
        expect do
          post :upload
        end.not_to change(Resource, :count)
      end

      it 'sets error flash message' do
        post :upload
        expect(flash[:error]).to eq('No file was uploaded')
      end

      it 'redirects to index' do
        post :upload
        expect(response).to redirect_to(action: 'index')
      end
    end

    context 'with invalid file (string instead of file object)' do
      it 'does not create a resource' do
        expect do
          post :upload, upload: { filename: 'not_a_file.txt' }
        end.not_to change(Resource, :count)
      end

      it 'sets error flash message' do
        post :upload, upload: { filename: 'not_a_file.txt' }
        expect(flash[:error]).to eq('No file was uploaded')
      end
    end

    context 'with image file' do
      before do
        FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
        png_data = "\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc\xf8\x0f\x00\x00\x01\x01\x00\x05\x18\xd8N\x00\x00\x00\x00IEND\xaeB`\x82"
        File.binwrite(Rails.root.join('spec/fixtures/files/test.png'), png_data)
      end

      after do
        FileUtils.rm_rf(Rails.root.join('spec/fixtures/files'))
      end

      let(:image_file) { fixture_file_upload('test.png', 'image/png') }

      it 'stores the image correctly' do
        post :upload, upload: { filename: image_file }
        resource = Resource.last
        expect(resource.file).to be_attached
        expect(resource.mime).to eq('image/png')
      end
    end

    context 'with PDF file' do
      before do
        FileUtils.mkdir_p(Rails.root.join('spec/fixtures/files'))
        File.write(Rails.root.join('spec/fixtures/files/test.pdf'), '%PDF-1.4 test')
      end

      after do
        FileUtils.rm_rf(Rails.root.join('spec/fixtures/files'))
      end

      let(:pdf_file) { fixture_file_upload('test.pdf', 'application/pdf') }

      it 'stores the PDF correctly' do
        post :upload, upload: { filename: pdf_file }
        resource = Resource.last
        expect(resource.file).to be_attached
        expect(resource.mime).to eq('application/pdf')
      end
    end
  end

  describe 'GET #destroy' do
    let!(:resource) { Factory(:resource) }

    it 'renders destroy template' do
      get :destroy, id: resource.id
      expect(response).to be_successful
      expect(response).to render_template('destroy')
    end

    it 'assigns the resource' do
      get :destroy, id: resource.id
      expect(assigns(:record)).to eq(resource)
    end
  end

  describe 'POST #destroy' do
    let!(:resource) { Factory(:resource) }

    it 'destroys the resource' do
      expect do
        post :destroy, id: resource.id
      end.to change(Resource, :count).by(-1)
    end

    it 'redirects to index' do
      post :destroy, id: resource.id
      expect(response).to redirect_to(action: 'index')
    end

    it 'sets success flash message' do
      post :destroy, id: resource.id
      expect(flash[:notice]).to eq('File deleted successfully')
    end

    context 'with attached file' do
      before do
        resource.file.attach(
          io: StringIO.new('test content'),
          filename: 'test.txt',
          content_type: 'text/plain'
        )
      end

      it 'destroys the resource and attachment' do
        expect do
          post :destroy, id: resource.id
        end.to change(Resource, :count).by(-1)
      end
    end

    context 'with non-existent resource' do
      it 'sets error flash message' do
        post :destroy, id: 99_999
        expect(flash[:error]).to eq('File not found')
      end

      it 'redirects to index' do
        post :destroy, id: 99_999
        expect(response).to redirect_to(action: 'index')
      end
    end
  end

  describe 'POST #update' do
    let!(:resource) { Factory(:resource) }
    let!(:article) { Factory(:article) }

    it 'updates resource attributes' do
      post :update, resource: { id: resource.id, mime: 'application/pdf' }
      resource.reload
      expect(resource.mime).to eq('application/pdf')
    end

    it 'redirects to index' do
      post :update, resource: { id: resource.id, mime: 'application/pdf' }
      expect(response).to redirect_to(action: 'index')
    end

    it 'can associate with an article' do
      post :update, resource: { id: resource.id, article_id: article.id }
      resource.reload
      expect(resource.article).to eq(article)
    end
  end

  describe 'GET #get_thumbnails' do
    before do
      Factory(:resource, mime: 'text/plain')
      Factory(:resource, mime: 'application/pdf')
    end

    it 'returns non-image resources' do
      get :get_thumbnails, position: 0
      expect(response).to be_successful
      expect(assigns(:resources)).not_to be_nil
    end

    it 'respects position parameter' do
      get :get_thumbnails, position: 0
      expect(assigns(:resources).size).to be <= 10
    end

    it 'renders without layout' do
      get :get_thumbnails, position: 0
      expect(response).to render_template(layout: false)
    end
  end
end
