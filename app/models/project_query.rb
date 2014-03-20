class ProjectQuery < Query

  self.queried_class = Project

  def self.available_columns
    columns = [
      QueryColumn.new(:name, :sortable => "#{Project.table_name}.name", :groupable => false),
      QueryColumn.new(:parent, :sortable => "#{Project.table_name}.name", :caption => :field_parent),
      QueryColumn.new(:status, :sortable => "#{Project.table_name}.status", :groupable => true),
      QueryColumn.new(:is_public, :sortable => "#{Project.table_name}.public", :groupable => true),
      QueryColumn.new(:identifier, :sortable => "#{Project.table_name}.identifier", :groupable => false),
      QueryColumn.new(:created_on, :sortable => "#{Project.table_name}.created_on", :default_order => 'desc'),
      QueryColumn.new(:updated_on, :sortable => "#{Project.table_name}.updated_on", :default_order => 'desc'),
      QueryColumn.new(:activity, :groupable => false, :sortable => ProjectSummary.sql_activity_records),
      QueryColumn.new(:issues, :sortable => false),
      QueryColumn.new(:role, :sortable => false),
      QueryColumn.new(:members, :sortable => false),
      QueryColumn.new(:users, :sortable => false)
    ]
    if show_description_as_a_column?
      columns << QueryColumn.new(:description)
    else
      columns << QueryColumn.new(:description, :inline => false)
    end
    columns << QueryColumn.new(:organizations, :sortable => false, :default_order => 'asc') if self.has_organizations_plugin?
    columns
  end

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= { 'status' => {:operator => "=", :values => [Project::STATUS_ACTIVE.to_s]} }
  end

  def initialize_available_filters
    project_custom_fields = ProjectCustomField.sorted

    project_values = all_projects_values
    add_available_filter("id",
                         :type => :list_optional, :values => project_values
    ) unless project_values.empty?

    member_values = []
    member_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    member_values += all_users.collect{|s| [s.name, s.id.to_s] }
    add_available_filter("member_id",
                         :type => :list, :values => member_values
    ) unless member_values.empty?

    add_available_filter "status", :type => :list, :values => [[l(:project_status_active), Project::STATUS_ACTIVE.to_s], [l(:project_status_closed), Project::STATUS_CLOSED.to_s], [l(:project_status_archived), Project::STATUS_ARCHIVED.to_s]]

    add_available_filter "created_on", :type => :date_past
    add_available_filter "updated_on", :type => :date_past
    add_available_filter "is_public", :type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]]

    if self.class.has_organizations_plugin?
      directions_values = Organization.select("name, id").where('direction = ?', true).order("name")
      add_available_filter("organizations", :type => :list, :values => directions_values.collect{|s| [s.name, s.id.to_s] })
      organizations_values = Organization.all.collect{|s| [s.fullname, s.id.to_s] }.sort_by{|v| v.first}
      add_available_filter("organization", :type => :list, :values => organizations_values)
    end

    add_custom_fields_filters(project_custom_fields)
  end

  # Returns a representation of the available filters for JSON serialization
  def available_filters_as_json
    json = {}
    available_filters.each do |field, options|
      options[:name] = l("field_name") if field == "id"
      options[:name] = l("label_member") if field == "member_id"
      json[field] = options.slice(:type, :name, :values).stringify_keys
    end
    json
  end

  def all_users
    timestamp = Member.maximum(:created_on)
    Rails.cache.fetch ['all-users', timestamp.to_i].join('/') do
      principals = Principal.active.uniq.joins(:members).where("#{Member.table_name}.project_id IN (SELECT id FROM #{Project.table_name})")
      principals.sort!
      principals.select { |p| p.is_a?(User) }
    end
  end

  # Returns the projects
  # Valid options are :offset, :limit, :include, :conditions
  def projects(options={})

    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

    Project.where(options[:conditions]).all(
        :conditions => statement,
        :include => (options[:include] || []).uniq,
        :limit  => options[:limit],
        :joins => joins_for_order_statement(order_option.join(',')),
        :order => order_option,
        :offset => options[:offset]
    )
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def sql_for_member_id_field(field, operator, value)
    if value.delete('me')
      value.push User.current.id.to_s
    end
    member_table = Member.table_name
    project_table = Project.table_name
    #return only the projects including all the selected members
    "#{project_table}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT #{member_table}.project_id FROM #{member_table} " +
        "JOIN #{project_table} ON #{member_table}.project_id = #{project_table}.id AND " +
        sql_for_field(field, '=', value, member_table, 'user_id') +
        "GROUP BY #{member_table}.project_id HAVING count(#{member_table}.project_id) = #{value.size}"+ ') '
  end


  def sql_for_organizations_field(field, operator, value)

    organization_table = Organization.table_name
    membership_table = OrganizationMembership.table_name

    "#{Project.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT project_id FROM #{membership_table} WHERE organization_id IN
                                                                        (WITH RECURSIVE rec_tree(parent_id, id, name, direction, depth) AS (
                                                                        SELECT t.parent_id, t.id, t.name, t.direction, 1
                                                                        FROM #{organization_table} t
                                                                        WHERE #{sql_for_field(field, '=', value, 't', 'id')}
                                                                        UNION ALL
                                                                        SELECT t.parent_id, t.id, t.name, rt.direction, rt.depth + 1
                                                                        FROM #{organization_table} t, rec_tree rt
                                                                        WHERE t.parent_id = rt.id
                                                                      )
                                                                      SELECT id FROM rec_tree))"
  end

  def sql_for_organization_field(field, operator, value)

    membership_table = OrganizationMembership.table_name

    "#{Project.table_name}.id #{ operator == '=' ? 'IN' : 'NOT IN' } (SELECT project_id FROM #{membership_table}
                                                                          WHERE #{sql_for_field(field, '=', value, membership_table, 'organization_id')}
                                                                        )"
  end

  def available_columns
    return @available_columns if @available_columns
    @available_columns = self.class.available_columns.dup
    @available_columns += ProjectCustomField.all.collect {|cf| QueryCustomFieldColumn.new(cf) }
    if self.class.has_organizations_plugin?
      # role display is NOT strictly related to organizations plugin but for
      # now the plugin only knows how to display these columns if the
      # organizations plugin is present
      @available_columns += Role.where("builtin = 0").order("position asc").all.collect { |role| QueryRoleColumn.new(role) }
    end
    @available_columns
  end

  def default_columns_names
    unless @default_columns_names
      @default_columns_names = []
      Setting['plugin_redmine_better_crossprojects']['default_columns'].split(",").each do |name|
        @default_columns_names << name.to_sym
      end
    end
    @default_columns_names
  end

  # Returns the project count
  def project_count
    Project.visible.count(:conditions => statement)
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  # Returns the project count by group or nil if query is not grouped
  def project_count_by_group
    r = nil
    if grouped?
      begin
        # Rails3 will raise an (unexpected) RecordNotFound if there's only a nil group value
        r = Project.count(:joins => joins_for_order_statement(group_by_statement), :group => group_by_statement, :conditions => statement)
      rescue ActiveRecord::RecordNotFound
        r = {nil => project_count}
      end
      c = group_by_column
      if c.is_a?(QueryCustomFieldColumn)
        r = r.keys.inject({}) {|h, k| h[c.custom_field.cast_value(k)] = r[k]; h}
      end
    end
    r
  rescue ::ActiveRecord::StatementInvalid => e
    raise StatementInvalid.new(e.message)
  end

  def self.unsorted_project_tree(projects, &block)
    ancestors = []
    projects.each do |project|
      while (ancestors.any? && !project.is_descendant_of?(ancestors.last))
        ancestors.pop
      end
      yield project, ancestors.size
      ancestors << project
    end
  end

  def self.show_description_as_a_column?
    Setting["plugin_redmine_better_crossprojects"]["show_description_as_a_column"]
  end

  private
  def self.has_organizations_plugin?
    Redmine::Plugin.installed?(:redmine_organizations)
  end
end

class QueryRoleColumn < QueryColumn

  def initialize(role)
      self.name = "role_#{role.id}".to_sym
      self.sortable = false
      self.groupable = false
      @inline = true
      @role = role
  end

  def caption
    @role.name
  end

  def role
    @role
  end

end
