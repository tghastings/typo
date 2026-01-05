# frozen_string_literal: true

module Admin
  class SeoController < Admin::BaseController
    cache_sweeper :blog_sweeper

    def index
      load_settings
      if File.exist? "#{::Rails.root}/public/robots.txt"
        @setting.robots = File.read("#{::Rails.root}/public/robots.txt")
      else
        build_robots
      end
    end

    def permalinks
      if request.post?
        if params[:setting]['permalink_format'] && (params[:setting]['permalink_format'] == 'custom')
          params[:setting]['permalink_format'] = params[:setting]['custom_permalink']
        end
        update
        return
      end

      load_settings
      if (@setting.permalink_format != '/%year%/%month%/%day%/%title%') &&
         (@setting.permalink_format != '/%year%/%month%/%title%') &&
         (@setting.permalink_format != '/%title%')
        @setting.custom_permalink = @setting.permalink_format
        @setting.permalink_format = 'custom'
      end
    end

    def titles
      load_settings
    end

    ALLOWED_ACTIONS = %w[index permalinks titles].freeze

    def update
      if request.post?
        Blog.transaction do
          params[:setting].each { |k, v| this_blog.send("#{k}=", v) }
          this_blog.save
          flash[:notice] = _('config updated.')
        end

        save_robots unless params[:setting][:robots].blank?

        redirect_action = ALLOWED_ACTIONS.include?(params[:from]) ? params[:from] : 'index'
        redirect_to action: redirect_action
      end
    rescue ActiveRecord::RecordInvalid
      render_action = ALLOWED_ACTIONS.include?(params[:from]) ? params[:from] : 'index'
      render action: render_action
    end

    private

    def load_settings
      @setting = this_blog
    end

    def save_robots
      return unless File.writable? "#{::Rails.root}/public/robots.txt"

      robots = File.new("#{::Rails.root}/public/robots.txt", 'r+')
      robots.write(params[:setting][:robots])
      robots.close
    end

    def build_robots
      robots = File.new("#{::Rails.root}/public/robots.txt", 'w+')
      line = "User-agent: *\nAllow: /\nDisallow: /admin\n"
      robots.write(line)
      robots.close
      @setting.robots = line
    end
  end
end
