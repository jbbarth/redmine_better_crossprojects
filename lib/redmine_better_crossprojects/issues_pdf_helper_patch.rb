include CustomFieldsHelper

module Redmine
  module Export
    module PDF
      module IssuesPdfHelper

        # Returns a PDF string of a list of projects
        def projects_to_pdf(projects, query)
          #do not display the "Activity" and "Issues" columns in PDF output
          remove_column(query, :activity)
          remove_column(query, :issues)
          issues_to_pdf(projects, l(:label_project_plural), query)
        end

        def remove_column(query, column_name)
          deleted_column = nil
          query.columns.each do |c|
            if c.is_a?(QueryColumn) && c.name == column_name
              deleted_column = c
              break
            end
          end
          query.available_columns.delete(deleted_column) if deleted_column
        end

        # fetch row values
        alias_method :fetch_row_values_without_bettercross_projects_plugin, :fetch_row_values
        def fetch_row_values(object, query, level)
          if (object.is_a?(Project))
            fetch_row_values_per_project(object, query, level)
          else
            fetch_row_values_without_bettercross_projects_plugin(object, query, level)
          end
        end

        # fetch row values
        def fetch_row_values_per_project(project, query, level)
          query.inline_columns.collect do |column|
            s = if column.is_a?(QueryCustomFieldColumn)
                  cv = project.custom_field_values.detect {|v| v.custom_field_id == column.custom_field.id}
                  show_value(cv, false)
                else
                  case column.name
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
                  when :users
                    value = project.send(column.name).size
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
                    value = project.send(column.name)
                  end

                  if column.name == :subject
                    value = "  " * level + value
                  end
                  if value.is_a?(Date)
                    format_date(value)
                  elsif value.is_a?(Time)
                    format_time(value)
                  elsif value.class.name == 'Array'
                    value.size
                  else
                    value # = ""
                  end
                end
            s.to_s
          end
        end

      end
    end
  end
end
