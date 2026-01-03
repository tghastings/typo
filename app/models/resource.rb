class Resource < ActiveRecord::Base
  has_one_attached :file

  # Legacy alias for old code that uses 'filename'
  alias_attribute :filename, :upload

  belongs_to :article, optional: true

  scope :without_images, -> { where("mime NOT LIKE '%image%'") }
  scope :images, -> { where("mime LIKE '%image%'") }
  scope :by_filename, -> { order("upload") }
  scope :by_created_at, -> { order("created_at DESC") }

  scope :without_images_by_filename, -> { without_images.by_filename }
  scope :images_by_created_at, -> { images.by_created_at }

  # Get the URL for the attached file
  def url
    return nil unless file.attached?
    Rails.application.routes.url_helpers.rails_blob_path(file, only_path: true)
  end

  # Get a variant URL for images (thumbnail or medium)
  def variant_url(size = :thumb)
    return nil unless file.attached?
    return nil unless mime&.include?('image')

    dimensions = case size.to_sym
                 when :thumb then [100, 100]
                 when :medium then [500, 500]
                 else [100, 100]
                 end

    Rails.application.routes.url_helpers.rails_representation_path(
      file.variant(resize_to_limit: dimensions),
      only_path: true
    )
  rescue
    url # Fallback to original if variant fails
  end

  # Legacy support: fullpath for old code
  def fullpath(file_name = nil)
    "#{::Rails.root.to_s}/public/files/#{file_name.nil? ? filename : file_name}"
  end

  # Legacy support: Check if file exists (for old code)
  def file_exists?
    file.attached?
  end
end
