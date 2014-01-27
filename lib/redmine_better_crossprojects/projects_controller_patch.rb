require_dependency 'projects_controller'

class Project < ActiveRecord::Base
  def activity
  end
end

class ProjectsController

  helper :sort
  include SortHelper
  include Redmine::Export::PDF

  # Lists visible projects
  def index
    retrieve_project_query
    @params = params
    @project_count_by_group = @query.project_count_by_group
    sort_init(@query.sort_criteria.empty? ? [['lft']] : @query.sort_criteria)
    sort_update(params['sort'].nil? ? ["lft"] : @query.sortable_columns)
    @query.sort_criteria = sort_criteria.to_a
    @projects = @query.projects(:order => sort_clause)

    # To display the 'members' column, we preload all names
    if @query.inline_columns.collect {|v| v.name}.include?(:members)
      users = User.select("id, firstname, lastname").all
      @users_map = {}
      users.each do |u|
        @users_map[u.id] = u.name
      end
    end

    if @query.inline_columns.collect {|c| c.name}.include?(:organizations)
      # @organizations = Organization.joins(:memberships).select("organizations.id, project_id").where("project_id IN (?)", @projects.collect(&:id)).collect{|orga| orga.memberships.map{|p| p.attributes.merge(orga.attributes) } }
      # @organizations_map = {}
      @directions_map = {}
      Organization.all.each do |o|
        unless @directions_map.key?(o)
          @directions_map[o] = o.direction_organization.name
        end
      end
    end

    #pre-load current user's memberships
    @memberships = User.current.memberships.inject({}) do |memo, membership|
      memo[membership.project_id] = membership.roles
      memo
    end

    respond_to do |format|
      format.html {
        render :template => 'projects/index'
      }
      format.api  {
        @offset, @limit = api_offset_and_limit
        @project_count = @projects.size
        @projects ||= Project.visible.offset(@offset).limit(@limit).order('lft').all
      }
      format.atom { render_feed(@projects, :title => "#{Setting.app_title}: #{l(:label_project_plural)}") }
      format.csv  { send_data query_to_csv(@projects, @query, params), :type => 'text/csv; header=present', :filename => 'projects.csv' }
      format.pdf  { send_data projects_to_pdf(@projects, @query), :type => 'application/pdf', :filename => 'projects.pdf' }
    end
  end

  private

    def retrieve_project_query
      if !params[:query_id].blank?
        puts "retrieve query 01"
        @query = ProjectQuery.find(params[:query_id])
        @query.project = @project
        session[:query] = {:id => @query.id}
        sort_clear
      elsif api_request? || params[:set_filter] || session[:query].nil? || session[:query][:project_id] != (@project ? @project.id : nil)
        # Give it a name, required to be valid
        puts "retrieve query 02"
        @query = ProjectQuery.new(:name => "_")
        @query.project = @project
        @query.build_from_params(params)
        session[:query] = {:filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
      else
        # retrieve from session
        puts "retrieve query 03"
        puts session[:query].inspect
        @query = ProjectQuery.find_by_id(session[:query][:id]) if session[:query][:id]
        @query ||= ProjectQuery.new(:name => "_", :filters => session[:query][:filters], :group_by => session[:query][:group_by], :column_names => session[:query][:column_names])
      end
    end
end


module Redmine
  module Export
    module PDF

      # Returns a PDF string of a list of projects
      def projects_to_pdf(projects, query)
        pdf = ITCPDF.new(current_language, "L")
        title = query.new_record? ? l(:label_project_plural) : query.name
        pdf.SetTitle(title)
        pdf.alias_nb_pages
        pdf.footer_date = format_date(Date.today)
        pdf.SetAutoPageBreak(false)
        pdf.AddPage("L")

        # Landscape A4 = 210 x 297 mm
        page_height   = 210
        page_width    = 297
        left_margin   = 10
        right_margin  = 10
        bottom_margin = 20
        row_height    = 4

        # column widths
        table_width = page_width - right_margin - left_margin
        col_width = []
        unless query.inline_columns.empty?
          col_width = calc_col_width(projects, query, table_width, pdf)
          table_width = col_width.inject(0) {|s,v| s += v}
        end

        # use full width if the description is displayed
        if table_width > 0 && query.has_column?(:description)
          col_width = col_width.map {|w| w * (page_width - right_margin - left_margin) / table_width}
          table_width = col_width.inject(0) {|s,v| s += v}
        end

        # title
        pdf.SetFontStyle('B',11)
        pdf.RDMCell(190,10, title)
        pdf.Ln
        render_table_header(pdf, query, col_width, row_height, table_width)
        previous_group = false
        ProjectQuery.unsorted_project_tree(projects) do |project, level|
          if query.grouped? &&
              (group = query.group_by_column.value(project)) != previous_group
            pdf.SetFontStyle('B',10)
            group_label = group.blank? ? 'None' : group.to_s.dup
            group_label << " (#{query.project_count_by_group[group]})"
            pdf.Bookmark group_label, 0, -1
            pdf.RDMCell(table_width, row_height * 2, group_label, 1, 1, 'L')
            pdf.SetFontStyle('',8)
            previous_group = group
          end

          # fetch row values
          col_values = fetch_row_values(project, query, level)

          # render it off-page to find the max height used
          base_x = pdf.GetX
          base_y = pdf.GetY
          pdf.SetY(2 * page_height)
          max_height = issues_to_pdf_write_cells(pdf, col_values, col_width, row_height)
          pdf.SetXY(base_x, base_y)

          # make new page if it doesn't fit on the current one
          space_left = page_height - base_y - bottom_margin
          if max_height > space_left
            pdf.AddPage("L")
            render_table_header(pdf, query, col_width, row_height, table_width)
            base_x = pdf.GetX
            base_y = pdf.GetY
          end

          # write the cells on page
          issues_to_pdf_write_cells(pdf, col_values, col_width, row_height)
          issues_to_pdf_draw_borders(pdf, base_x, base_y, base_y + max_height, 0, col_width)
          pdf.SetY(base_y + max_height);

          if query.has_column?(:description) && project.description?
            pdf.SetX(10)
            pdf.SetAutoPageBreak(true, 20)
            pdf.RDMwriteHTMLCell(0, 5, 10, 0, project.description.to_s, project.attachments, "LRBT")
            pdf.SetAutoPageBreak(false)
          end
        end

        if projects.size == Setting.issues_export_limit.to_i
          pdf.SetFontStyle('B',10)
          pdf.RDMCell(0, row_height, '...')
        end
        pdf.Output
      end

      # fetch row values
      def fetch_row_values(issue, query, level)
        query.inline_columns.collect do |column|
          s = if column.is_a?(QueryCustomFieldColumn)
                cv = issue.custom_field_values.detect {|v| v.custom_field_id == column.custom_field.id}
                show_value(cv)
              else
                value = issue.send(column.name)
                if column.name == :subject
                  value = "  " * level + value
                end
                if value.is_a?(Date)
                  format_date(value)
                elsif value.is_a?(Time)
                  format_time(value)
                elsif value.class.name == 'Array'
                  values = []
                  value.collect{|v| v.direction_organization.name }.uniq.compact.join(', ')
                else
                  value
                end
              end
          s.to_s
        end
      end

    end
  end
end

module QueriesHelper

  def csv_content(column, issue)
    value = column.value(issue)
    if value.is_a?(Array)
      value.collect {|v| csv_value(column, issue, v)}.uniq.compact.join(', ')
    else
      csv_value(column, issue, value)
    end
  end

  def csv_value(column, issue, value)
    case value.class.name
      when 'Time'
        format_time(value)
      when 'Date'
        format_date(value)
      when 'Float'
        sprintf("%.2f", value).gsub('.', l(:general_csv_decimal_separator))
      when 'IssueRelation'
        other = value.other_issue(issue)
        l(value.label_for(issue)) + " ##{other.id}"
      when 'Organization'
        value.direction_organization.name
      else
        value.to_s
    end
  end

end
