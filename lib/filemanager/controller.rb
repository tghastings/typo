# frozen_string_literal: true

#   controller.rb
#   Copyright (C) 2008  Leon Li
#
#   You may redistribute it and/or modify it under the same
#   license terms as Ruby.
require 'shellwords'

module Filemanager
  module Controller
    # Sanitize filename to prevent path traversal attacks
    def sanitize_filename(filename)
      return '' if filename.nil?

      # Remove any path traversal attempts and null bytes
      filename.to_s.gsub('..', '').gsub(%r{[/\\]}, '').gsub("\x00", '')
    end

    # Validate that a path is within the allowed resource path
    def safe_path?(path)
      return false if path.nil?

      expanded = File.expand_path(path)
      resource_expanded = File.expand_path(FM_RESOURCES_PATH)
      expanded.start_with?(resource_expanded)
    end

    def set_up
      @lock_path = FM_LOCK_PATH
      @source = params[:source]
      @source = decode(@source) unless @source.nil?
      # Enhanced path traversal protection
      raw_path = params[:path].to_s
      @path = raw_path.blank? || raw_path.include?('..') || raw_path.include?("\x00") ? '' : raw_path
      @path = '' if @path == '/'
      @path = decode(@path)
      @resource_path = FM_RESOURCES_PATH
      @current_path = @resource_path + @path

      # Validate the path is within allowed directory
      unless safe_path?(@current_path)
        @current_path = @resource_path
        @path = ''
      end

      @current_file = (File.directory?(@current_path) ? Dir.new(@current_path) : File.new(@current_path))
      @parent_path = if !@path.blank? && !@path.rindex('/').nil?
                       @path.rindex('/').zero? ? '/' : @path[0..(@path.rindex('/') - 1)]
                     end
      @path_suffix = @path.index('.').nil? || @path[-1] == '.' ? '' : @path[(@path.index('.') + 1)..].downcase
      return unless File.directory?(@current_path)

      @all_files = Dir.entries(@current_path)
      @directories = @all_files.map { |f| File.directory?(@current_path + File::SEPARATOR + f) ? f : nil }.compact
      @files = @all_files.map { |f| File.directory?(@current_path + File::SEPARATOR + f) ? nil : f }.compact
      @file_total_size = @files.inject(0) { |size, f| size + File.size(@current_path + File::SEPARATOR + f) }
    end

    def tear_off
      @current_file&.close
    end

    def index; end

    def view
      #    respond_to do |wants|
      #      wants.js {  render :text => File.size(@current_path) > 1000000 ? 'File too big' : File.read(@current_path) }
      #    end
    end

    def file_content
      File.size(@current_path) > 1_000_000 ? 'File too big' : File.read(@current_path)
    end

    #  def office
    #    render :action=>'excel' if is_excel?
    #    render :action=>'word' if is_word?
    #    render :action=>'ppt' if is_ppt?
    #    render :action=>'help' if is_help?
    #  end

    def rename
      old_filename = sanitize_filename(decode(params[:old_name]))
      new_filename = sanitize_filename(decode(params[:new_name]))
      return error if old_filename.blank? || new_filename.blank?

      # Build and validate paths - expand to canonical form for security
      old_path = File.expand_path(File.join(@current_path, old_filename))
      new_path = File.expand_path(File.join(@current_path, new_filename))
      resource_root = File.expand_path(FM_RESOURCES_PATH)

      # Verify both paths are within allowed directory
      return error unless old_path.start_with?(resource_root) && new_path.start_with?(resource_root)

      File.rename(old_path, new_path)
      success
    end

    def remove
      safe_sources = @source.map do |s|
        sanitized = sanitize_filename(s)
        path = @current_path + File::SEPARATOR + sanitized
        safe_path?(path) ? path : nil
      end.compact
      FileUtils.rm_rf(safe_sources)
      success
    end

    def new_file
      filename = sanitize_filename(decode(params[:new_name]))
      return error if filename.blank?

      # Build and validate path - expand to canonical form for security
      file_path = File.expand_path(File.join(@current_path, filename))
      resource_root = File.expand_path(FM_RESOURCES_PATH)

      # Verify path is within allowed directory
      return error unless file_path.start_with?(resource_root)

      File.new(file_path, 'w')
      success
    end

    def new_folder
      dirname = sanitize_filename(decode(params[:new_name]))
      return error if dirname.blank?

      path = @current_path + File::SEPARATOR + dirname
      return error unless safe_path?(path)

      Dir.mkdir(path)
      success
    end

    def copy
      session[:source] = @source.map { |s| @current_path + File::SEPARATOR + s }
      session[:remove] = false
      success
    end

    def cut
      session[:source] = @source.map { |s| @current_path + File::SEPARATOR + s }
      session[:remove] = true
      success
    end

    def paste
      return error if session[:remove].nil? || session[:source].nil?

      begin
        if session[:remove] == true
          FileUtils.mv(session[:source],
                       @current_path)
        else
          FileUtils.cp_r(session[:source], @current_path)
        end
        session[:remove] = nil
        session[:source] = nil
        success
      rescue StandardError => e
        result(e)
      end
    end

    def download
      now = Time.new
      now = "#{now.to_i}#{now.usec}"
      temp_file = "#{FM_TEMP_DIR}#{File::SEPARATOR}#{now}.zip"

      # Sanitize and escape all filenames for shell safety
      safe_sources = @source.map { |s| sanitize_filename(s) }.reject(&:blank?)
      return error if safe_sources.empty?

      safe_sources.map { |s| Shellwords.escape(s) }.join(' ')
      Shellwords.escape(temp_file)

      FileUtils.cd(@current_path) do |_dir|
        system('zip', '-r', temp_file, *safe_sources)
      end
      send_file(temp_file)
    end

    def upload
      file = params[:upload]
      filename = sanitize_filename(decode(file.original_filename))
      return error if filename.blank?

      path = @current_path + File::SEPARATOR + filename
      return error unless safe_path?(path)

      File.binwrite(path, file.read)
      to_index
    end

    # TODO
    def adjust_size; end

    # TODO
    def rotate; end

    # TODO
    def unzip
      filename = sanitize_filename(decode(params[:old_name]))
      return error if filename.blank?

      # Use array form of system() to avoid shell injection
      FileUtils.cd(@current_path) do |_dir|
        system('unzip', '-o', filename)
      end
      to_index
    end

    def to_index
      redirect_to action: 'index', path: encode(@path)
    end

    def success
      result('SUCCESS')
    end

    def error
      result('ERROR')
    end

    def result(message)
      respond_to do |wants|
        wants.js { render text: message }
      end
    end

    # methods for view
    def method_missing(method_id, *)
      method_id_s = method_id.to_s
      if method_id_s[0, 3] == 'is_' && method_id_s[-1, 1] == '?'
        # rubocop:disable Style/DocumentDynamicEvalDefinition
        # Defines: def is_image?(*args); FM_IMAGE_TYPES.include?(@path_suffix); end
        instance_eval %{
	                        def #{method_id}(*args)
	                          FM_#{method_id_s[3..-2].upcase}_TYPES.include?(@path_suffix)
	                        end
	                      }, __FILE__, __LINE__ - 4
        # rubocop:enable Style/DocumentDynamicEvalDefinition
        send(method_id, *)
      else
        super
      end
    end

    def transfer(from, to, target)
      if FM_ENCODING_TO.nil?
        target
      elsif target.is_a?(Array)
        target.map { |i| to.nil? ? i : Iconv.conv(to, from, i) }
      else
        Iconv.conv(to, from, target)
      end
    end

    def encode(target)
      transfer(FM_ENCODING_FROM, FM_ENCODING_TO, target)
    end

    def decode(target)
      transfer(FM_ENCODING_TO, FM_ENCODING_FROM, target)
    end

    def hsize(size)
      size /= 1024
      if size > 1024
        size /= 1024
        "#{format('%0.2f', size)} mb"
      else
        "#{format('%0.2f', size)} kb"
      end
    end

    def get_file_type(file)
      type = File.extname(file)

      unless type.blank?
        type = type.downcase[1..]
        return type if FM_SUPPORT_TYPES.include?(type)
      end
      FM_UNKNOWN_TYPE
    end
  end
end
