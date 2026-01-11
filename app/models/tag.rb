# frozen_string_literal: true

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :articles, -> { order('created_at DESC') }

  validates_uniqueness_of :name

  # Satisfy GroupingController needs.
  attr_accessor :description, :keywords

  def self.get(name)
    tagname = name.to_url
    find_or_create_by(name: tagname) do |tag|
      tag.display_name = name
    end
  end

  def self.find_by_name_or_display_name(tagname, name)
    where('name = ? OR display_name = ? OR display_name = ?', tagname, tagname, name).first
  end

  def ensure_naming_conventions
    self.display_name = name if display_name.blank?
    self.name = display_name.to_url
  end

  before_save :ensure_naming_conventions

  # Whitelist allowed ORDER BY clauses to prevent SQL injection
  ALLOWED_ORDER_CLAUSES = {
    'article_counter DESC' => 'article_counter DESC',
    'article_counter ASC' => 'article_counter ASC',
    'name ASC' => 'tags.name ASC',
    'name DESC' => 'tags.name DESC',
    'display_name ASC' => 'tags.display_name ASC',
    'display_name DESC' => 'tags.display_name DESC'
  }.freeze

  def self.find_all_with_article_counters(limit = 20, orderby = 'article_counter DESC', start = 0)
    # Only count published articles
    # Validate orderby against whitelist to prevent SQL injection
    safe_orderby = ALLOWED_ORDER_CLAUSES[orderby] || 'article_counter DESC'

    # Use Arel for safe query building
    tags_table = Tag.arel_table
    articles_table = Article.arel_table
    join_table_name = reflect_on_association(:articles).join_table
    join_arel = Arel::Table.new(join_table_name)

    # Build the query using Arel
    query = tags_table
            .project(
              tags_table[:id],
              tags_table[:name],
              tags_table[:display_name],
              join_arel[:article_id].count.as('article_counter')
            )
            .join(join_arel).on(join_arel[:tag_id].eq(tags_table[:id]))
            .join(articles_table).on(
              join_arel[:article_id].eq(articles_table[:id])
              .and(articles_table[:published].eq(true))
            )
            .group(tags_table[:id], tags_table[:name], tags_table[:display_name])
            .order(Arel.sql(safe_orderby))
            .take(limit)
            .skip(start)

    find_by_sql(query.to_sql).each { |item| item.article_counter = item.article_counter.to_i }
  end

  def self.merge(from, to)
    # Use parameterized query to prevent SQL injection
    connection.execute(sanitize_sql_array(['UPDATE articles_tags SET tag_id = ? WHERE tag_id = ?', to.to_i, from.to_i]))
  end

  def self.find_by_permalink(name)
    find_by_name(name)
  end

  def self.to_prefix
    'tag'
  end

  # Return all tags with the char or string
  # send by parameter
  def self.find_with_char(char)
    where('name LIKE ?', "%#{char}%").order('name ASC')
  end

  def self.collection_to_string(tags)
    tags.map(&:display_name).sort.map { |name| name =~ / / ? "\"#{name}\"" : name }.join ', '
  end

  def published_articles
    articles.already_published
  end

  def permalink
    name
  end

  def permalink_url(_anchor = nil, only_path = false)
    blog = Blog.default # remove me...

    blog.url_for(
      controller: 'tags',
      action: 'show',
      id: permalink,
      only_path: only_path
    )
  end

  def to_param
    permalink
  end
end
