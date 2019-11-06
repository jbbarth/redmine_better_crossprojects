require_dependency 'queries_helper'

module PluginBetterCrossProjects
  module QueriesHelper

    def column_value(column, item, value)
      if column.name == :parent && value.kind_of?(Project)
        value ? (value.visible? ? link_to_project(value) : "##{value.id}") : ''
      else
        super
      end
    end

    def csv_content(column, project)
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
          if organizations_map[project.id] && organizations_map[project.id][$1.to_i]
            value = organizations_map[project.id][$1.to_i].join(', ')
          else
            value = ""
          end
        when /function_(\d+)$/
          if organizations_map[project.id] && organizations_map[project.id][column.name.to_s]
            value = organizations_map[project.id][column.name.to_s].uniq.join(', ').html_safe
          end
        else
          return super
      end
      if value.is_a?(Array)
        value.collect {|v| csv_value(column, project, v)}.uniq.compact.join(', ')
      else
        csv_value(column, project, value)
      end
    end

    def csv_value(column, object, value)
      if value.class.name == 'Organization'
        value.direction_organization.name
      else
        super
      end
    end

  end
end

QueriesHelper.prepend PluginBetterCrossProjects::QueriesHelper
ActionView::Base.prepend QueriesHelper
IssuesController.prepend QueriesHelper
ProjectsController.prepend QueriesHelper
