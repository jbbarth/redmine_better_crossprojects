require_dependency 'queries_helper'

module QueriesHelper

  unless instance_methods.include?(:column_value_with_better_crossprojects)
    def column_value_with_better_crossprojects(column, issue, value)
      if column.name == :parent && value.kind_of?(Project)
        value ? (value.visible? ? link_to_project(value) : "##{value.id}") : ''
      else
        column_value_without_better_crossprojects(column, issue, value)
      end
    end
    alias_method_chain :column_value, :better_crossprojects
  end

  unless instance_methods.include?(:csv_content_with_better_crossprojects)
    def csv_content_with_better_crossprojects(column, project)
      case column.name
        when :issues
          value = ""
        when :organizations
          value = directions_map[project.id]
        when :role
          if @memberships[project.id].present?
            value = @memberships[project.id].map(&:name).join(", ")
          else
            value = l(:label_role_non_member)
          end
        when :members
          value = members_map[project.id]
        when /role_(\d+)$/
          if organizations_map[project.id.to_s] && organizations_map[project.id.to_s][$1]
            value = organizations_map[project.id.to_s][$1].join(', ')
          else
            value = ""
          end
        when /function_(\d+)$/
          if organizations_map[project.id.to_s] && organizations_map[project.id.to_s][column.name.to_s]
            value = organizations_map[project.id.to_s][column.name.to_s].uniq.join(', ').html_safe
          end
        else
          value = column.value(project)
      end
      if value.is_a?(Array)
        value.collect {|v| csv_value(column, project, v)}.uniq.compact.join(', ')
      else
        csv_value(column, project, value)
      end
    end
    alias_method_chain :csv_content, :better_crossprojects
  end

  unless instance_methods.include?(:csv_value_with_better_crossprojects)
    def csv_value_with_better_crossprojects(column, object, value)
      if value.class.name == 'Organization'
        value.direction_organization.name
      else
        csv_value_without_better_crossprojects(column, object, value)
      end
    end
    alias_method_chain :csv_value, :better_crossprojects
  end

end


