require_dependency 'projects_controller'
require_dependency 'project'

class ProjectsController

  helper :sort
  include SortHelper
  include Redmine::Export::PDF
  include IssuesHelper
  include QueriesHelper

  # Lists visible projects
  def index
    retrieve_project_query

    if params[:format] == 'pdf' && @query.column_names && @query.column_names.count > 40
      redirect_to(:back)
      flash[:error] = l(:please_select_less_columns)
      return
    end

    @params = request.params
    @project_count_by_group = @query.project_count_by_group
    sort_init(@query.sort_criteria.empty? ? [['lft']] : @query.sort_criteria)
    sort_update(params['sort'].nil? ? ["lft"] : @query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a

    query_options = {:order => sort_clause}
    if @query.inline_columns.any? {|col| col.is_a?(QueryCustomFieldColumn)}
      query_options.merge!(:include => [:custom_values])
    end
    @projects = @query.projects(query_options)

    #pre-load current user's memberships
    @memberships = User.current.memberships.inject({}) do |memo, membership|
      memo[membership.project_id] = membership.roles
      memo
    end

    respond_to do |format|
      format.html {
        render :template => 'projects/index'
      }
      format.api {
        @offset, @limit = api_offset_and_limit
        @project_count = @projects.size
        @projects ||= Project.visible.offset(@offset).limit(@limit).order('lft').all
      }
      format.atom {render_feed(@projects, :title => "#{Setting.app_title}: #{l(:label_project_plural)}")}
      format.csv {
        # remove_hidden_projects
        send_data query_to_csv(@projects, @query, params[:csv]), :type => 'text/csv', :filename => 'projects.csv'
      }
      format.pdf {
        remove_hidden_projects
        send_data projects_to_pdf(@projects, @query), :type => 'application/pdf', :filename => 'projects.pdf'
      }
    end
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def remove_hidden_projects
    if params[:visible_projects].present?
      visible_ids = params['visible_projects'].split(",").map(&:to_i)
      @projects.select! {|p| p.id.in?(visible_ids)}
    end
  end

  def members_map
    @members_map ||= Rails.cache.fetch("projects-members-#{Member.maximum("created_on").to_i}") do
      user_names_map = {}
      @query.all_users.each do |u|
        user_names_map[u.id] = u.name
      end
      members_by_project_map = {}
      @projects.each do |p|
        members = p.send("members")
        members_by_project_map[p.id] = members.collect {|m| "#{user_names_map[m.user_id]}"}.compact.join(', ').html_safe
      end
      members_by_project_map
    end
  end

  helper_method :members_map

  def organizations_map
    cache_strategy = ['all-organizations', Member.maximum("created_on").to_i, Organization.maximum("updated_at").to_i, 2].join('/')
    @organizations_map ||= Rails.cache.fetch cache_strategy do
      orgas_fullnames = {}
      Organization.all.each do |o|
        orgas_fullnames[o.id.to_s] = o.fullname
      end

      sql = Organization.select("organizations.id, project_id, role_id").joins(:users => {:members => :member_roles}).order("project_id, role_id, organizations.id").group("project_id, role_id, organizations.id").to_sql
      array = ActiveRecord::Base.connection.execute(sql)
      map = {}
      array.each do |record|
        unless map[record["project_id"]]
          map[record["project_id"]] = {}
        end
        unless map[record["project_id"]][record["role_id"]]
          map[record["project_id"]][record["role_id"]] = []
        end
        map[record["project_id"]][record["role_id"]] << orgas_fullnames[record["id"]]
      end

      if Redmine::Plugin.installed?(:redmine_limited_visibility)
        sql = Organization.select("organizations.id, project_id, function_id").joins(:users => {:members => :member_functions}).order("project_id, function_id, organizations.id").group("project_id, function_id, organizations.id").to_sql
        array = ActiveRecord::Base.connection.execute(sql)
        array.each do |record|
          unless map[record["project_id"]]
            map[record["project_id"]] = {}
          end
          unless map[record["project_id"]]["function_#{record["function_id"]}"]
            map[record["project_id"]]["function_#{record["function_id"]}"] = []
          end
          map[record["project_id"]]["function_#{record["function_id"]}"] << orgas_fullnames[record["id"]]
          map[record["project_id"]]["function_#{record["function_id"]}"] << orgas_fullnames[record["id"]]
        end
      end

      map
    end
  end

  helper_method :organizations_map

  def directions_map
    @directions_map ||= Rails.cache.fetch ['all-directions', Member.maximum("created_on").to_i, Organization.maximum("updated_at").to_i].join('/') do
      map = {}
      @projects.each do |p|
        orgas = p.send("organizations")
        directions = []
        orgas.each do |o|
          directions << o.direction_organization.name
        end
        directions.uniq!
        if (directions.size > 1)
          directions = directions - ["CPII"]
        end
        map[p.id] = directions.join(', ').html_safe
      end
      map
    end
  end

  helper_method :directions_map

  private

  def retrieve_project_query
    if !params[:query_id].blank?
      @query = ProjectQuery.find(params[:query_id])
      @query.project = @project
      session[:project_query] = {:id => @query.id}
      sort_clear
    elsif api_request? || params[:set_filter] || session[:project_query].nil?
      # Give it a name, required to be valid
      @query = ProjectQuery.new(:name => "_")
      @query.project = @project
      @query.build_from_params(params)
      session[:project_query] = {:filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      # retrieve from session
      @query = ProjectQuery.find_by_id(session[:project_query][:id]) if session[:project_query][:id]
      @query ||= ProjectQuery.new(:name => "_", :filters => session[:project_query][:filters], :group_by => session[:project_query][:group_by], :column_names => session[:project_query][:column_names])
    end
  end
end

class Project
  def activity;
  end
end
