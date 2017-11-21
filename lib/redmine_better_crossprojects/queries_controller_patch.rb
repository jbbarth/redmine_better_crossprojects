require_dependency 'queries_controller'

class QueriesController

  # Returns the values for a query filter
  def filter
    q = query_class.new
    if params[:project_id].present?
      q.project = Project.find(params[:project_id])
    end

    # PATCH START -> Do not check permission when the query is a ProjectQuery
    unless User.current.allowed_to?(q.class.view_permission, q.project, :global => true) || query_class == ProjectQuery
    # PATCH END
      raise Unauthorized
    end

    filter = q.available_filters[params[:name].to_s]
    values = filter ? filter.values : []

    render :json => values
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
