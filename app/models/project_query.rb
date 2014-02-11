class ProjectQuery < Query

  self.queried_class = Project

  self.available_columns = [
      QueryColumn.new(:name, :sortable => "#{Project.table_name}.name", :groupable => true),
      QueryColumn.new(:parent, :sortable => "#{Project.table_name}.name", :caption => :field_parent),
      QueryColumn.new(:status, :sortable => "#{Project.table_name}.status", :groupable => true),
      QueryColumn.new(:is_public, :sortable => "#{Project.table_name}.public", :groupabel => true),
      QueryColumn.new(:created_on, :sortable => "#{Project.table_name}.created_on", :default_order => 'desc'),
      QueryColumn.new(:updated_on, :sortable => "#{Project.table_name}.updated_on", :default_order => 'desc'),
      QueryColumn.new(:organizations, :sortable => false, :default_order => 'asc'),
      QueryColumn.new(:activity, :sortable => false),
      QueryColumn.new(:issues, :sortable => false),
      QueryColumn.new(:description, :inline => false),
      QueryColumn.new(:role, :sortable => false),
      QueryColumn.new(:members, :sortable => false)
  ]

  def initialize(attributes=nil, *args)
    super attributes
    self.filters ||= Hash.new
  end

  def initialize_available_filters
    project_custom_fields = ProjectCustomField.all

    project_values = all_projects_values
    add_available_filter("id",
                         :type => :list_optional, :values => project_values
    ) unless project_values.empty?

    principals = Principal.member_of(all_projects)
    principals.uniq!
    principals.sort!
    users = principals.select {|p| p.is_a?(User)}
    member_values = []
    member_values << ["<< #{l(:label_me)} >>", "me"] if User.current.logged?
    member_values += users.collect{|s| [s.name, s.id.to_s] }
    add_available_filter("member_id",
                         :type => :list, :values => member_values
    ) unless member_values.empty?

    add_available_filter "created_on", :type => :date_past
    add_available_filter "updated_on", :type => :date_past
    add_available_filter "is_public", :type => :list, :values => [[l(:general_text_yes), "1"], [l(:general_text_no), "0"]]

    # Custom CPII filter TODO remove specific code + dependence to orga plugin before merging to master
    directions_values = Organization.select("name, id").where('direction = ?', true).order("name")
    add_available_filter("organizations", :type => :list, :values => directions_values.collect{|s| [s.name, s.id.to_s] })
    organizations_values = Organization.all.collect{|s| [s.fullname, s.id.to_s] }.sort_by{|v| v.first}
    add_available_filter("organization", :type => :list, :values => organizations_values)

    add_custom_fields_filters(project_custom_fields)
  end

  # Returns a representation of the available filters for JSON serialization
  def available_filters_as_json
    json = {}
    available_filters.each do |field, options|
      options[:name] = l("field_name") if field == "id"
      options[:name] = l("label_member") if field == "member_id"
      # options[:name] = l("label_member_plural") if field == "members"
      json[field] = options.slice(:type, :name, :values).stringify_keys
    end
    json
  end

  # Returns the projects
  # Valid options are :offset, :limit, :include, :conditions
  def projects(options={})

    order_option = [group_by_sort_order, options[:order]].flatten.reject(&:blank?)

    Project.visible.where(options[:conditions]).all(
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

  def sql_for_status_id_field(field, operator, value)
    case operator
      when "o"
        sql = "#{queried_table_name}.status = 1"
      when "c"
        sql = "#{queried_table_name}.status = 9 "
      else
        raise "Unknown query operator #{operator}"
    end
    sql
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

    # Custom CPII TODO Remove before merge to master branch
    @available_columns += Role.where("builtin = 0").order("position asc").all.collect { |role| QueryRoleColumn.new(role) }

    @available_columns
  end

  def default_columns_names
    @default_columns_names ||= begin
      default_columns = [ :name
      ]
      default_columns << ('cf_' + CustomField.select(:id).where(name: "Domaine", type: "ProjectCustomField").first.id.to_s).to_sym
      default_columns << ('cf_' + CustomField.select(:id).where(name: "Type", type: "ProjectCustomField").first.id.to_s).to_sym
      default_columns << :organizations
      # default_columns << :role
      default_columns << :issues
      default_columns << :activity
    end
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
        r = Project.visible.count(:joins => joins_for_order_statement(group_by_statement), :group => group_by_statement, :conditions => statement)
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