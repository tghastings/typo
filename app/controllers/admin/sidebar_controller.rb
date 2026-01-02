class Admin::SidebarController < Admin::BaseController
  def index
    @available = available
    # Reset the staged position based on the active position.
    Sidebar.where('active_position is null').delete_all
    flash_sidebars
    begin
      @active = Sidebar.where.not(active_position: nil).order('active_position ASC').to_a unless @active
    rescue => e
      logger.error e
      # Avoiding the view to crash
      @active = []
      flash[:error] = _("It seems something went wrong. Maybe some of your sidebars are actually missing and you should either reinstall them or remove them manually")
    end
  end

  def set_active
    # Handle empty or missing params
    active_params = params[:active] || []

    # Get all available plugins
    klass_for = available.inject({}) do |hash, klass|
      hash.merge({ klass.short_name => klass })
    end

    # Get all already active plugins
    activemap = flash_sidebars.to_a.inject({}) do |h, sb_id|
      begin
        sb = Sidebar.find(sb_id.to_i)
        sb ? h.merge(sb.html_id => sb_id) : h
      rescue ActiveRecord::RecordNotFound
        h
      end
    end

    # Figure out which plugins are referenced by the params[:active] array and
    # lay them out in a easy accessible sequential array
    flash[:sidebars] = active_params.map do |name|
      if klass_for.has_key?(name)
        new_sidebar_id = klass_for[name].create.id
        @new_item = Sidebar.find(new_sidebar_id)
        new_sidebar_id
      elsif activemap.has_key?(name)
        activemap[name]
      end
    end.compact

    # Auto-save positions to database immediately
    Sidebar.transaction do
      # Clear all active positions first
      Sidebar.where.not(active_position: nil).update_all(active_position: nil)

      # Set new positions
      flash[:sidebars].each_with_index do |sidebar_id, position|
        Sidebar.where(id: sidebar_id).update_all(active_position: position)
      end

      # Clean up orphaned sidebars
      Sidebar.where(active_position: nil).delete_all
    end

    respond_to do |format|
      format.js
      format.json { render json: { success: true, sidebars: flash[:sidebars] } }
      format.html { redirect_to action: :index }
    end
  end

  def remove
    flash[:sidebars] = flash_sidebars.reject do |sb_id|
      sb_id == params[:id].to_i
    end
    @element_to_remove = params[:element]
  end

  def publish
    Sidebar.transaction do
      position = 0
      params[:configure] ||= { }
      # Crappy workaround to rails update_all bug with PgSQL / SQLite
      ActiveRecord::Base.connection.execute("update sidebars set active_position=null")
      flash_sidebars.each do |id|
        sidebar = Sidebar.find(id)
        raw_attribs = params[:configure][id.to_s] || {}
        sb_attribs = raw_attribs.respond_to?(:permit!) ? raw_attribs.permit!.to_h : raw_attribs.to_h
        # If it's a checkbox and unchecked, convert the 0 to false
        # This is ugly.  Anyone have an improvement?
        sidebar.fields.each do |field|
          sb_attribs[field.key] = field.canonicalize(sb_attribs[field.key])
        end

        sidebar.update(config: sb_attribs.to_h, active_position: position)
        position += 1
      end
      Sidebar.where('active_position is null').delete_all
    end
    ::PageCache.sweep_all
    flash[:success] = _("Sidebar changes published successfully")
    redirect_to action: :index
  end

  protected

  def show_available
    render :partial => 'availables', :object => available
  end

  def available
    ::Sidebar.available_sidebars
  end

  def flash_sidebars
    unless flash[:sidebars]
      begin
        active = Sidebar.where.not(active_position: nil).order('active_position ASC')
        flash[:sidebars] = active.map {|sb| sb.id }
      rescue => e
        logger.error e
        # Avoiding the view to crash
        @active = []
        flash[:error] = _("It seems something went wrong. Maybe some of your sidebars are actually missing and you should either reinstall them or remove them manually")
      end
    end
    flash[:sidebars]
  end

  helper_method :available
end
