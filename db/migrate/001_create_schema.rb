class CreateSchema < ActiveRecord::Migration[7.0]
  def change
    create_table :users do |t|
      t.string :login
      t.string :password
      t.string :email
      t.text :name
      t.boolean :notify_via_email, default: false
      t.boolean :notify_on_new_articles, default: false
      t.boolean :notify_on_comments, default: false
      t.integer :profile_id
      t.string :remember_token
      t.datetime :remember_token_expires_at
      t.string :text_filter_id, default: ''
      t.string :state, default: 'active'
      t.datetime :last_connection
      t.text :settings
      t.integer :resource_id
      t.timestamps
    end
    add_index :users, :login, unique: true

    create_table :contents do |t|
      t.string :type
      t.string :title
      t.string :author
      t.text :body
      t.text :extended
      t.text :excerpt
      t.datetime :published_at
      t.integer :user_id
      t.string :permalink
      t.string :guid
      t.integer :text_filter_id
      t.text :whiteboard
      t.string :name
      t.boolean :published, default: false
      t.boolean :allow_pings
      t.boolean :allow_comments
      t.string :post_type, default: 'read'
      t.integer :blog_id, default: 1
      t.string :state
      t.integer :parent_id
      t.string :password
      t.timestamps
    end
    add_index :contents, :published_at
    add_index :contents, :user_id
    add_index :contents, :permalink
    add_index :contents, :type

    create_table :feedback do |t|
      t.string :type
      t.string :title
      t.string :author
      t.text :body
      t.text :excerpt
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :user_id
      t.string :guid
      t.integer :text_filter_id
      t.text :whiteboard
      t.integer :article_id
      t.string :email
      t.string :url
      t.string :ip, limit: 40
      t.string :blog_name
      t.boolean :published, default: false
      t.datetime :published_at
      t.string :state
      t.boolean :status_confirmed
      t.string :user_agent
    end
    add_index :feedback, :article_id
    add_index :feedback, :user_id

    create_table :categories do |t|
      t.string :name
      t.integer :position
      t.string :permalink
      t.text :keywords
      t.text :description
      t.integer :parent_id
      t.timestamps
    end

    create_table :articles_categories, id: false do |t|
      t.integer :article_id
      t.integer :category_id
    end
    add_index :articles_categories, :article_id
    add_index :articles_categories, :category_id

    create_table :tags do |t|
      t.string :name
      t.datetime :created_at
      t.string :display_name
    end
    add_index :tags, :name

    create_table :articles_tags, id: false do |t|
      t.integer :article_id
      t.integer :tag_id
    end
    add_index :articles_tags, :article_id
    add_index :articles_tags, :tag_id

    create_table :resources do |t|
      t.integer :size
      t.string :upload
      t.string :mime
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :article_id
      t.boolean :itunes_metadata
      t.string :itunes_author
      t.string :itunes_subtitle
      t.integer :itunes_duration
      t.text :itunes_summary
      t.string :itunes_keywords
      t.string :itunes_category
      t.boolean :itunes_explicit
      t.integer :blog_id
    end

    create_table :blogs do |t|
      t.text :settings
      t.string :base_url
    end

    create_table :sidebars do |t|
      t.integer :active_position
      t.text :config
      t.integer :staged_position
      t.string :type
      t.integer :blog_id
    end

    create_table :redirects do |t|
      t.string :from_path
      t.string :to_path
      t.integer :blog_id
      t.timestamps
    end

    create_table :triggers do |t|
      t.integer :pending_item_id
      t.string :pending_item_type
      t.datetime :due_at
      t.string :trigger_method
    end

    create_table :profiles do |t|
      t.string :label
      t.string :nicename
      t.text :modules
    end

    create_table :profile_rights, id: false do |t|
      t.integer :profile_id
      t.integer :right_id
    end

    create_table :rights do |t|
      t.string :name
      t.text :description
    end

    create_table :post_types do |t|
      t.string :name
      t.string :permalink
      t.text :description
    end

    create_table :text_filters do |t|
      t.string :name
      t.text :description
      t.string :markup
      t.text :filters
      t.text :params
    end

    create_table :notifications do |t|
      t.integer :content_id
      t.integer :user_id
      t.boolean :is_read, default: false
      t.timestamps
    end

    # Join table for Article has_and_belongs_to_many :tags
    create_table :contents_tags, id: false do |t|
      t.integer :article_id
      t.integer :tag_id
    end
    add_index :contents_tags, :article_id
    add_index :contents_tags, :tag_id

    # Redirections for content
    create_table :redirections do |t|
      t.integer :content_id
      t.integer :redirect_id
      t.string :from_path
      t.string :to_path
      t.timestamps
    end
    add_index :redirections, :content_id

    # Categorizations (join table)
    create_table :categorizations do |t|
      t.integer :article_id
      t.integer :category_id
      t.boolean :is_primary, default: false
    end
    add_index :categorizations, :article_id
    add_index :categorizations, :category_id

    # Pings table
    create_table :pings do |t|
      t.integer :article_id
      t.string :url
      t.datetime :created_at
    end
    add_index :pings, :article_id

    # Trackbacks table (inherits from feedback, but just in case)
    # Already covered by feedback table via STI
  end
end
