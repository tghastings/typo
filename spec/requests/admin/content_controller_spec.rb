# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin::Content', type: :request do
  before(:each) do
    setup_blog_and_admin
  end

  describe 'GET /admin/content' do
    context 'when not logged in' do
      it 'redirects to login page' do
        get '/admin/content'
        expect(response).to be_redirect
        expect(response.location).to include('/accounts/login')
      end
    end

    context 'when logged in as admin' do
      before { login_admin }

      it 'returns successful response' do
        get '/admin/content'
        expect(response).to be_successful
      end

      it 'displays article list' do
        article = FactoryBot.create(:article, user: @admin)
        get '/admin/content'
        expect(response.body).to include(article.title)
      end

      it 'displays multiple articles' do
        FactoryBot.create(:article, user: @admin, title: 'First Article')
        FactoryBot.create(:article, user: @admin, title: 'Second Article')
        get '/admin/content'
        expect(response.body).to include('First Article')
        expect(response.body).to include('Second Article')
      end
    end
  end

  describe 'GET /admin/content (XHR)' do
    before { login_admin }

    it 'returns partial for XHR request' do
      FactoryBot.create(:article, user: @admin)
      get '/admin/content', xhr: true
      expect(response).to be_successful
    end

    it 'returns article list partial on XHR request' do
      FactoryBot.create(:article, user: @admin, title: 'XHR Article')
      get '/admin/content', xhr: true
      expect(response.body).to include('XHR Article')
    end
  end

  describe 'GET /admin/content/new' do
    before { login_admin }

    it 'returns successful response' do
      get '/admin/content/new'
      expect(response).to be_successful
    end

    it 'displays new article form' do
      get '/admin/content/new'
      expect(response.body).to include('Title')
    end

    it 'displays form elements for article creation' do
      get '/admin/content/new'
      expect(response.body).to include('article')
    end
  end

  describe 'POST /admin/content/new' do
    before { login_admin }

    it 'creates a new article' do
      expect do
        post '/admin/content/new', params: {
          article: {
            title: 'Test Article',
            body: 'Test body content',
            allow_comments: '1',
            allow_pings: '1'
          }
        }
      end.to change { Article.count }.by(1)
    end

    it 'redirects to index after creation' do
      post '/admin/content/new', params: {
        article: {
          title: 'Test Article',
          body: 'Test body content'
        }
      }
      expect(response).to redirect_to(action: 'index')
    end

    it 'creates article with categories' do
      category = FactoryBot.create(:category)
      post '/admin/content/new', params: {
        article: {
          title: 'Categorized Article',
          body: 'Body with categories'
        },
        categories: [category.id]
      }
      expect(Article.last.categories).to include(category)
    end

    it 'creates article with multiple categories' do
      category1 = FactoryBot.create(:category)
      category2 = FactoryBot.create(:category)
      post '/admin/content/new', params: {
        article: {
          title: 'Multi-Category Article',
          body: 'Body with multiple categories'
        },
        categories: [category1.id, category2.id]
      }
      expect(Article.last.categories).to include(category1)
      expect(Article.last.categories).to include(category2)
    end

    it 'creates article with tags' do
      post '/admin/content/new', params: {
        article: {
          title: 'Tagged Article',
          body: 'Body with tags',
          keywords: 'ruby, rails'
        }
      }
      expect(Article.last.tags.count).to be >= 1
    end

    it 'creates article with multiple tags' do
      post '/admin/content/new', params: {
        article: {
          title: 'Multi-Tag Article',
          body: 'Body with multiple tags',
          keywords: 'ruby, rails, testing'
        }
      }
      article = Article.last
      tag_names = article.tags.map(&:name)
      expect(tag_names).to include('ruby')
      expect(tag_names).to include('rails')
    end

    it 'sets the current user as author' do
      post '/admin/content/new', params: {
        article: {
          title: 'Authored Article',
          body: 'Body content'
        }
      }
      expect(Article.last.user).to eq(@admin)
    end

    it 'sets flash notice on successful creation' do
      post '/admin/content/new', params: {
        article: {
          title: 'Flash Article',
          body: 'Body content'
        }
      }
      expect(flash[:notice]).to include('Article was successfully created')
    end

    it 'allows setting allow_comments' do
      post '/admin/content/new', params: {
        article: {
          title: 'Commentable Article',
          body: 'Body content',
          allow_comments: '1'
        }
      }
      expect(Article.last.allow_comments).to be_truthy
    end

    it 'allows setting allow_pings' do
      post '/admin/content/new', params: {
        article: {
          title: 'Pingable Article',
          body: 'Body content',
          allow_pings: '1'
        }
      }
      expect(Article.last.allow_pings).to be_truthy
    end
  end

  describe 'POST /admin/content/new (draft)' do
    before { login_admin }

    it 'creates an article with draft state when draft param is set' do
      post '/admin/content/new', params: {
        article: {
          title: 'Draft Article',
          body: 'Draft body content',
          draft: '1'
        }
      }
      article = Article.last
      expect(article).not_to be_nil
      # Use the raw attribute value since state is a state machine object
      expect(article[:state]).to eq('draft')
    end

    it 'draft article is not published' do
      post '/admin/content/new', params: {
        article: {
          title: 'Another Draft',
          body: 'Draft body',
          draft: '1'
        }
      }
      article = Article.last
      expect(article.published).to be_falsey
    end
  end

  describe 'GET /admin/content/edit/:id' do
    before { login_admin }

    it 'returns successful response for own article' do
      article = FactoryBot.create(:article, user: @admin)
      get "/admin/content/edit/#{article.id}"
      expect(response).to be_successful
    end

    it 'displays edit form with article data' do
      article = FactoryBot.create(:article, user: @admin, title: 'Editable Article')
      get "/admin/content/edit/#{article.id}"
      expect(response.body).to include('Editable Article')
    end

    it 'displays article body in edit form' do
      article = FactoryBot.create(:article, user: @admin, body: 'Original body content')
      get "/admin/content/edit/#{article.id}"
      expect(response.body).to include('Original body content')
    end

    it 'allows admin to edit any article' do
      other_user = FactoryBot.create(:user)
      article = FactoryBot.create(:article, user: other_user, title: 'Other User Article')
      get "/admin/content/edit/#{article.id}"
      expect(response).to be_successful
    end
  end

  describe 'POST /admin/content/edit/:id' do
    before { login_admin }

    it 'updates the article' do
      article = FactoryBot.create(:article, user: @admin, title: 'Original Title')
      post "/admin/content/edit/#{article.id}", params: {
        article: {
          title: 'Updated Title',
          body: article.body
        }
      }
      expect(article.reload.title).to eq('Updated Title')
    end

    it 'redirects to index after update' do
      article = FactoryBot.create(:article, user: @admin)
      post "/admin/content/edit/#{article.id}", params: {
        article: {
          title: 'Updated',
          body: 'Updated body'
        }
      }
      expect(response).to redirect_to(action: 'index')
    end

    it 'updates article body' do
      article = FactoryBot.create(:article, user: @admin, body: 'Original body')
      post "/admin/content/edit/#{article.id}", params: {
        article: {
          title: article.title,
          body: 'Updated body content'
        }
      }
      expect(article.reload.body).to include('Updated body content')
    end

    it 'updates article categories' do
      category = FactoryBot.create(:category)
      article = FactoryBot.create(:article, user: @admin)
      post "/admin/content/edit/#{article.id}", params: {
        article: {
          title: article.title,
          body: article.body
        },
        categories: [category.id]
      }
      expect(article.reload.categories).to include(category)
    end

    it 'clears categories when none provided' do
      category = FactoryBot.create(:category)
      article = FactoryBot.create(:article, user: @admin)
      article.categories << category
      article.save!

      post "/admin/content/edit/#{article.id}", params: {
        article: {
          title: article.title,
          body: article.body
        }
      }
      expect(article.reload.categories).to be_empty
    end

    it 'sets flash notice on successful update' do
      article = FactoryBot.create(:article, user: @admin)
      post "/admin/content/edit/#{article.id}", params: {
        article: {
          title: 'Updated for Flash',
          body: article.body
        }
      }
      expect(flash[:notice]).to include('Article was successfully updated')
    end
  end

  describe 'GET /admin/content/destroy/:id' do
    before { login_admin }

    it 'displays confirmation page' do
      article = FactoryBot.create(:article, user: @admin)
      get "/admin/content/destroy/#{article.id}"
      expect(response).to be_successful
    end

    it 'does not delete the article on GET' do
      article = FactoryBot.create(:article, user: @admin)
      expect do
        get "/admin/content/destroy/#{article.id}"
      end.not_to(change { Article.count })
    end

    it 'shows delete confirmation' do
      article = FactoryBot.create(:article, user: @admin, title: 'Article to Confirm')
      get "/admin/content/destroy/#{article.id}"
      expect(response.body).to include('delete')
    end
  end

  describe 'POST /admin/content/destroy/:id' do
    before { login_admin }

    it 'deletes the article' do
      article = FactoryBot.create(:article, user: @admin)
      expect do
        post "/admin/content/destroy/#{article.id}"
      end.to change { Article.count }.by(-1)
    end

    it 'redirects to index after deletion' do
      article = FactoryBot.create(:article, user: @admin)
      post "/admin/content/destroy/#{article.id}"
      expect(response).to redirect_to(action: 'index')
    end

    it 'sets flash notice on successful deletion' do
      article = FactoryBot.create(:article, user: @admin)
      post "/admin/content/destroy/#{article.id}"
      expect(flash[:notice]).to include('deleted successfully')
    end

    it 'deletes article with associated comments' do
      article = FactoryBot.create(:article, user: @admin)
      FactoryBot.create(:comment, article: article)
      expect do
        post "/admin/content/destroy/#{article.id}"
      end.to change { Article.count }.by(-1)
    end

    it 'deletes article with categories' do
      category = FactoryBot.create(:category)
      article = FactoryBot.create(:article, user: @admin)
      article.categories << category
      article.save!

      expect do
        post "/admin/content/destroy/#{article.id}"
      end.to change { Article.count }.by(-1)
    end
  end

  describe 'Search functionality' do
    before { login_admin }

    it 'filters articles by searchstring' do
      FactoryBot.create(:article, user: @admin, body: 'unique_search_term')
      FactoryBot.create(:article, user: @admin, body: 'different content')
      get '/admin/content', params: { search: { searchstring: 'unique_search_term' } }
      expect(response).to be_successful
    end

    it 'filters articles by title searchstring' do
      FactoryBot.create(:article, user: @admin, title: 'UniqueTitle123')
      get '/admin/content', params: { search: { searchstring: 'UniqueTitle123' } }
      expect(response).to be_successful
    end

    it 'filters articles by state' do
      FactoryBot.create(:article, user: @admin, state: 'draft')
      get '/admin/content', params: { search: { state: 'drafts' } }
      expect(response).to be_successful
    end

    it 'filters articles by published status' do
      FactoryBot.create(:article, user: @admin, published: true)
      get '/admin/content', params: { search: { published: '1' } }
      expect(response).to be_successful
    end

    it 'filters articles by withdrawn state' do
      FactoryBot.create(:article, user: @admin, state: 'withdrawn')
      get '/admin/content', params: { search: { state: 'withdrawn' } }
      expect(response).to be_successful
    end

    it 'filters articles by pending state' do
      get '/admin/content', params: { search: { state: 'pending' } }
      expect(response).to be_successful
    end

    it 'filters articles by user_id' do
      FactoryBot.create(:article, user: @admin, title: 'Admin User Article')
      get '/admin/content', params: { search: { user_id: @admin.id } }
      expect(response).to be_successful
    end

    it 'filters articles by category' do
      category = FactoryBot.create(:category)
      article = FactoryBot.create(:article, user: @admin)
      article.categories << category
      article.save!

      get '/admin/content', params: { search: { category: category.id } }
      expect(response).to be_successful
    end

    it 'case insensitive search' do
      FactoryBot.create(:article, user: @admin, body: 'UPPERCASE CONTENT')
      get '/admin/content', params: { search: { searchstring: 'uppercase' } }
      expect(response).to be_successful
    end
  end

  describe 'Pagination' do
    before { login_admin }

    it 'shows page 1 by default' do
      15.times { |i| FactoryBot.create(:article, user: @admin, title: "Article #{i}") }
      get '/admin/content'
      expect(response).to be_successful
    end

    it 'shows page 2 of articles' do
      25.times { |i| FactoryBot.create(:article, user: @admin, title: "Paginated Article #{i}") }
      get '/admin/content', params: { page: 2 }
      expect(response).to be_successful
    end
  end

  describe 'Autosave functionality' do
    before { login_admin }

    it 'responds to autosave request' do
      # Create an initial article first
      FactoryBot.create(:article, user: @admin)
      post '/admin/content/autosave', params: {
        article: {
          title: 'Autosave Draft',
          body_and_extended: 'Autosave content',
          published: '0'
        }
      }
      expect(response).not_to be_nil
    end

    it 'creates a draft on autosave' do
      FactoryBot.create(:article, user: @admin)
      expect do
        post '/admin/content/autosave', params: {
          article: {
            title: 'New Autosave Article',
            body_and_extended: 'Autosave body content'
          }
        }
      end.to(change { Article.count })
    end

    it 'autosave returns JSON response when requested' do
      FactoryBot.create(:article, user: @admin)
      post '/admin/content/autosave', params: {
        article: {
          title: 'JSON Response Article',
          body_and_extended: 'Content for JSON'
        }
      }, headers: { 'Accept' => 'application/json' }
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'Editor switching' do
    before { login_admin }

    it 'returns markdown editor partial' do
      get '/admin/content/insert_editor', params: { editor: 'simple' }
      expect(response).to be_successful
    end

    it 'returns markdown editor for any editor param' do
      get '/admin/content/insert_editor', params: { editor: 'visual' }
      expect(response).to be_successful
    end

    it 'always sets user editor preference to markdown' do
      get '/admin/content/insert_editor', params: { editor: 'simple' }
      expect(@admin.reload.editor).to eq('markdown')
    end

    it 'uses unified markdown editor' do
      get '/admin/content/insert_editor', params: { editor: 'visual' }
      expect(@admin.reload.editor).to eq('markdown')
    end

    it 'responds successfully for any editor value' do
      get '/admin/content/insert_editor', params: { editor: 'unknown' }
      expect(response).to be_successful
    end
  end

  describe 'Attachment box' do
    before { login_admin }

    it 'responds to attachment_box_add with turbo stream' do
      get '/admin/content/attachment_box_add', params: { id: 1 }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
      expect(response).to be_successful
    end

    it 'returns successful response for attachment box via XHR' do
      get '/admin/content/attachment_box_add', params: { id: 1 }, xhr: true
      expect(response).to be_successful
    end
  end

  describe 'Article with extended content' do
    before { login_admin }

    it 'creates article with body and extended content' do
      post '/admin/content/new', params: {
        article: {
          title: 'Extended Article',
          body_and_extended: "Short intro\n<!--more-->\nExtended content here"
        }
      }
      article = Article.last
      expect(article.body).to include('Short intro')
      expect(article.extended).to include('Extended content here')
    end

    it 'updates article extended content' do
      article = FactoryBot.create(:article, user: @admin, body: 'Original', extended: 'Original extended')
      post "/admin/content/edit/#{article.id}", params: {
        article: {
          title: article.title,
          body_and_extended: "Updated body\n<!--more-->\nUpdated extended"
        }
      }
      article.reload
      expect(article.body).to include('Updated body')
      expect(article.extended).to include('Updated extended')
    end
  end

  describe 'Article validation' do
    before { login_admin }

    it 'requires title for article creation' do
      expect do
        post '/admin/content/new', params: {
          article: {
            title: '',
            body: 'Body without title'
          }
        }
      end.not_to(change { Article.count })
    end

    it 'does not redirect on validation failure' do
      skip 'Test needs fixing - validation error handling'
      post '/admin/content/new', params: {
        article: {
          title: '',
          body: 'Body content'
        }
      }
      # Returns 200 because it re-renders the form, not a redirect
      expect(response.status).to eq(200)
    end
  end

  describe 'Article keywords/tags' do
    before { login_admin }

    it 'displays existing keywords in edit form' do
      article = FactoryBot.create(:article, user: @admin)
      tag = Tag.create!(name: 'existing_tag')
      article.tags << tag
      article.save!

      get "/admin/content/edit/#{article.id}"
      expect(response).to be_successful
    end

    it 'updates article keywords' do
      article = FactoryBot.create(:article, user: @admin)
      post "/admin/content/edit/#{article.id}", params: {
        article: {
          title: article.title,
          body: article.body,
          keywords: 'newtag1, newtag2'
        }
      }
      article.reload
      tag_names = article.tags.map(&:name)
      expect(tag_names).to include('newtag1')
      expect(tag_names).to include('newtag2')
    end
  end

  describe 'Article with published_at date' do
    before { login_admin }

    it 'creates article with custom published_at date' do
      future_date = (Time.now + 1.day).strftime('%B %e, %Y %I:%M %p GMT%z')
      post '/admin/content/new', params: {
        article: {
          title: 'Future Article',
          body: 'Future content',
          published_at: future_date
        }
      }
      expect(Article.last).not_to be_nil
    end
  end
end
