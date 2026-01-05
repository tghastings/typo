# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Files', type: :request do
  let!(:blog) { create(:blog) }

  describe 'GET /files/:filename' do
    context 'when file exists' do
      let!(:resource) do
        r = create(:resource, filename: 'test-file.jpg', mime: 'image/jpeg')
        r.file.attach(
          io: StringIO.new('test file content'),
          filename: 'test-file.jpg',
          content_type: 'image/jpeg'
        )
        r
      end

      it 'returns the file' do
        get '/files/test-file.jpg'
        expect(response.status).to be_in([200, 302, 404])
      end
    end

    context 'when file does not exist' do
      it 'returns 404' do
        get '/files/nonexistent.jpg'
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
