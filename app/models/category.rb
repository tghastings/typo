class Category < ActiveRecord::Base
  acts_as_list

  # Tree structure (replacing acts_as_tree for Rails 8 compatibility)
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :children, class_name: 'Category', foreign_key: 'parent_id'

  has_many :categorizations
  has_many :articles, -> { order("published_at DESC, created_at DESC") }, through: :categorizations

  default_scope { order(name: :asc) }

  validates :name, presence: true
  validates :name, uniqueness: { on: :create }

  before_save :set_permalink

  def self.to_prefix
    'category'
  end

  def self.reorder(serialized_list)
    transaction do
      serialized_list.each_with_index do |cid, index|
        find(cid).update_attribute "position", index
      end
    end
  end

  def self.reorder_alpha
    reorder unscoped.order('UPPER(name)').pluck(:id)
  end

  def self.find_by_permalink(permalink)
    find_by(permalink: permalink) or raise ActiveRecord::RecordNotFound
  end

  def self.find_all_with_article_counters(maxcount=nil)
    find_by_sql([%{
      SELECT categories.id, categories.name, categories.permalink, categories.position, COUNT(articles.id) AS article_counter
      FROM #{Category.table_name} categories
        LEFT OUTER JOIN categorizations
          ON categorizations.category_id = categories.id
        LEFT OUTER JOIN #{Article.table_name} articles
          ON (categorizations.article_id = articles.id AND articles.published = ?)
      GROUP BY categories.id, categories.name, categories.position, categories.permalink
      ORDER BY position
    }, true]).each { |item| item.article_counter = item.article_counter.to_i }
  end

  def published_articles
    articles.already_published
  end

  def display_name
    name
  end

  def permalink_url(anchor=nil, only_path=false)
    blog = Blog.default
    blog.url_for(
      controller: '/categories',
      action: 'show',
      id: permalink,
      only_path: only_path
    )
  end

  def to_param
    permalink
  end

  protected

  def set_permalink
    self.permalink = self.name.to_permalink if self.permalink.blank?
  end
end
