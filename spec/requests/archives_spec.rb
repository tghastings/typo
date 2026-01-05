# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Archives', type: :request do
  let!(:blog) { create(:blog) }

  describe 'GET /archives' do
    context 'with articles' do
      before do
        create(:article, published: true, published_at: 1.day.ago)
      end

      it 'returns success' do
        get '/archives'
        expect(response).to have_http_status(:success)
      end
    end

    context 'without articles' do
      it 'redirects' do
        get '/archives'
        expect(response.status).to be_in([301, 302])
      end
    end
  end
end
