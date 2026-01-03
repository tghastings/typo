# Public file serving controller
# Serves uploaded files from Active Storage
class FilesController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    resource = Resource.find_by(upload: params[:filename])

    if resource&.file&.attached?
      # Stream the file directly
      send_data resource.file.download,
                filename: resource.filename,
                type: resource.mime,
                disposition: 'inline'
    else
      head :not_found
    end
  end
end
