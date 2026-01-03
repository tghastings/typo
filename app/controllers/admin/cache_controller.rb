require 'find'

class Admin::CacheController < Admin::BaseController
  def index
    @cache_size = 0
    @cache_number = 0

    cache_dir = TypoBlog::Application.config.action_controller.page_cache_directory

    # Ensure cache directory exists
    if cache_dir.present?
      FileUtils.mkdir_p(cache_dir) unless File.exist?(cache_dir)
    end

    if request.post?
      begin
        # Clear Rails cache store
        Rails.cache.clear

        # Clear Typo page cache
        PageCache.sweep_all

        flash.now[:notice] = _("Cache was successfully sweeped")
      rescue => e
        Rails.logger.error "Cache sweep error: #{e.message}"
        flash.now[:error] = _("Oops, something wrong happened. Cache could not be cleaned") + " (#{e.message})"
      end
    end

    # Count cache files
    if cache_dir.present? && File.exist?(cache_dir)
      Find.find(cache_dir) do |path|
        if FileTest.directory?(path)
          if File.basename(path)[0] == ?.
            Find.prune
          else
            next
          end
        else
          @cache_size += FileTest.size(path)
          @cache_number += 1
        end
      end
    end
  end

end
