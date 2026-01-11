# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Tags', type: :request do
  let!(:blog) { create(:blog) }

  describe 'GET /tag/:name' do
    context 'with articles' do
      before do
        tag = create(:tag, name: 'ruby')
        article = create(:article, published: true, published_at: 1.day.ago)
        article.tags << tag
      end

      it 'returns success' do
        get '/tag/ruby'
        expect(response.status).to be_in([200, 301, 302])
      end
    end

    context 'without articles' do
      it 'redirects when tag has no articles' do
        create(:tag, name: 'empty')
        get '/tag/empty'
        expect(response).to redirect_to('/')
      end
    end
  end

  describe 'GET /tags' do
    it 'returns success' do
      get '/tags'
      expect(response).to have_http_status(:success)
    end
  end
end
