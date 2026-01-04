# frozen_string_literal: true

module Admin
  class ResourcesController < Admin::BaseController
    cache_sweeper :blog_sweeper

    def upload
      if request.post?
        uploaded_file = params.dig(:upload, :filename) || params[:file]

        unless uploaded_file.respond_to?(:original_filename)
          flash[:error] = _('No file was uploaded')
          respond_to do |format|
            format.html { redirect_to action: 'index' }
            format.json { render json: { error: 'No file was uploaded' }, status: :unprocessable_entity }
          end
          return
        end

        mime = uploaded_file.content_type.presence || 'application/octet-stream'

        @resource = Resource.new(
          upload: uploaded_file.original_filename,
          mime: mime,
          size: uploaded_file.size
        )

        if @resource.save
          @resource.file.attach(uploaded_file)

          flash[:notice] = _('File uploaded successfully: ') + uploaded_file.original_filename

          respond_to do |format|
            format.html { redirect_to action: 'index' }
            format.json do
              render json: {
                url: @resource.url,
                thumbnail: @resource.variant_url(:thumb),
                medium: @resource.variant_url(:medium),
                id: @resource.id,
                filename: @resource.filename,
                mime: @resource.mime
              }
            end
          end
        else
          flash[:error] = _('Unable to save file')
          respond_to do |format|
            format.html { redirect_to action: 'index' }
            format.json { render json: { error: 'Unable to save' }, status: :unprocessable_entity }
          end
        end
      end
    rescue StandardError => e
      Rails.logger.error "Upload error: #{e.message}"
      flash[:error] = _('Unable to upload file')

      respond_to do |format|
        format.html { redirect_to action: 'index' }
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end

    def update
      @resource = Resource.find(params[:resource][:id])
      @resource.attributes = resource_params if params[:resource].present?

      if request.post? && @resource.save
        flash[:notice] = _('Metadata was successfully updated.')
      else
        flash[:error] = _('Not all metadata was defined correctly.')
        @resource.errors.each do |error|
          flash[:error] << "<br />#{error.full_message}"
        end
      end
      redirect_to action: 'index'
    end

    def index
      @r = Resource.new
      @resources = Resource.order('created_at DESC').page(params[:page]).per(this_blog.admin_display_elements)
    end

    def get_thumbnails
      position = params[:position].to_i
      @resources = Resource.without_images.by_created_at.offset(position).limit(10)
      render 'get_thumbnails', layout: false
    end

    def destroy
      @record = Resource.find(params[:id])
      return render 'admin/shared/destroy' unless request.post?

      @record.destroy
      flash[:notice] = _('File deleted successfully')
      redirect_to action: 'index'
    rescue ActiveRecord::RecordNotFound
      flash[:error] = _('File not found')
      redirect_to action: 'index'
    end

    # Serve files directly - bypasses Active Storage routing
    def serve
      resource = Resource.find_by(upload: params[:filename])

      if resource&.file&.attached?
        send_data resource.file.download,
                  filename: resource.filename,
                  type: resource.mime,
                  disposition: 'inline'
      else
        head :not_found
      end
    end

    private

    def resource_params
      params.require(:resource).permit(:upload, :mime, :article_id)
    end
  end
end
