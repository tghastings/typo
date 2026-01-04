# frozen_string_literal: true

class Redirect < ActiveRecord::Base
  validates_uniqueness_of :from_path
  validates_presence_of :to_path

  has_many :redirections

  has_many :contents, through: :redirections

  def full_to_path
    path = to_path
    return path if path =~ %r{^(https?)://([^/]*)(.*)}

    blog = Blog.default
    url_root = blog.root_path
    # Prepend url_root if path doesn't already start with it
    path = url_root + path unless url_root.nil? || url_root.empty? || (path[0, url_root.length] == url_root)
    # Return full URL with base_url
    blog.base_url.sub(/#{Regexp.escape(url_root)}$/, '') + path
  end

  def shorten
    if (temp_token = random_token) && self.class.find_by_from_path(temp_token).nil?
      temp_token
    else
      shorten
    end
  end

  private

  def random_token
    characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890'
    temp_token = ''
    srand
    6.times do
      pos = rand(characters.length)
      temp_token += characters[pos..pos]
    end
    temp_token
  end
end
