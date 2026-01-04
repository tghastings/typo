# frozen_string_literal: true

require 'spec_helper'

describe AuthorsController do
  describe '#show' do
    let!(:blog) { Factory(:blog) }
    let!(:user) { Factory(:user) }
    let!(:article) { Factory(:article, user: user) }
    let!(:unpublished_article) { Factory(:unpublished_article, user: user) }

    describe 'as html' do
      before do
        get 'show', id: user.login
      end

      it 'renders the :show template' do
        expect(response).to render_template(:show)
      end

      it 'assigns author' do
        expect(assigns(:author)).to eq(user)
      end

      it 'assigns articles as published articles' do
        expect(assigns(:articles)).to eq([article])
      end

      describe 'when rendered' do
        render_views

        it 'has a link to the rss feed' do
          expect(response).to have_selector("head>link[href=\"http://myblog.net/author/#{user.login}.rss\"]")
        end

        it 'has a link to the atom feed' do
          expect(response).to have_selector("head>link[href=\"http://myblog.net/author/#{user.login}.atom\"]")
        end
      end
    end

    describe 'as an atom feed' do
      before do
        get 'show', id: user.login, format: 'atom'
      end

      it 'assigns articles as published articles' do
        expect(assigns(:articles)).to eq([article])
      end

      it 'renders the atom template' do
        expect(response).to be_success
        expect(response).to render_template('show_atom_feed')
      end

      it 'does not render layout' do
        # No layout should be rendered for feeds
      end
    end

    describe 'as an rss feed' do
      before do
        get 'show', id: user.login, format: 'rss'
      end

      it 'assigns articles as published articles' do
        expect(assigns(:articles)).to eq([article])
      end

      it 'renders the rss template' do
        expect(response).to be_success
        expect(response).to render_template('show_rss_feed')
      end

      it 'does not render layout' do
        # No layout should be rendered for feeds
      end
    end
  end
end

describe AuthorsController, 'SEO options' do
  render_views

  it 'should never have meta keywords with deactivated option' do
    Factory(:blog, use_meta_keyword: false)
    Factory(:user, login: 'henri')
    get 'show', id: 'henri'
    expect(response).not_to have_selector('head>meta[name="keywords"]')
  end

  it 'should never have meta keywords with deactivated option' do
    Factory(:blog, use_meta_keyword: true)
    Factory(:user, login: 'alice')
    get 'show', id: 'alice'
    expect(response).not_to have_selector('head>meta[name="keywords"]')
  end
end
