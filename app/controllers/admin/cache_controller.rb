# frozen_string_literal: true

require 'find'

module Admin
  class CacheController < Admin::BaseController
    def index
      @cache_size = 0
      @cache_number = 0

      cache_dir = TypoBlog::Application.config.action_controller.page_cache_directory

      # Ensure cache directory exists
      FileUtils.mkdir_p(cache_dir) if cache_dir.present? && !File.exist?(cache_dir)

      if request.post?
        begin
          # Clear Rails cache store
          Rails.cache.clear

          # Clear Typo page cache files directly
          FileUtils.rm_rf(Dir.glob("#{cache_dir}/*")) if cache_dir.present? && File.exist?(cache_dir) && cache_dir != "#{Rails.root}/public"

          flash.now[:notice] = _('Cache was successfully sweeped')
        rescue StandardError => e
          Rails.logger.error "Cache sweep error: #{e.message}"
          flash.now[:error] = _('Oops, something wrong happened. Cache could not be cleaned') + " (#{e.message})"
        end
      end

      # Count cache files
      return unless cache_dir.present? && File.exist?(cache_dir)

      Find.find(cache_dir) do |path|
        if FileTest.directory?(path)
          next unless File.basename(path)[0] == '.'

          Find.prune

        else
          @cache_size += FileTest.size(path)
          @cache_number += 1
        end
      end
    end
  end
end
