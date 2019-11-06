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

          # START MODIFIED COPY OF STANDARD CODE from issues_to_pdf(issues, project, query) #TODO Split original method in Redmine core
          issues = projects # Use projects instead of issues
          title = l(:label_project_plural)

          pdf = ITCPDF.new(current_language, "L")
          pdf.set_title(title)
          pdf.alias_nb_pages
          pdf.footer_date = format_date(User.current.today)
          pdf.set_auto_page_break(false)
          pdf.add_page("L")

          # Landscape A4 = 210 x 297 mm
          page_height   = pdf.get_page_height # 210
          page_width    = pdf.get_page_width  # 297
          left_margin   = pdf.get_original_margins['left'] # 10
          right_margin  = pdf.get_original_margins['right'] # 10
          bottom_margin = pdf.get_footer_margin
          row_height    = 4

          # column widths
          table_width = page_width - right_margin - left_margin
          col_width = []
          unless query.inline_columns.empty?
            col_width = calc_col_width(issues, query, table_width, pdf)
            table_width = col_width.inject(0, :+)
          end

          # START PATCH
          unless ProjectQuery.show_description_as_a_column?
            # use full width if the description or last_notes are displayed
            if table_width > 0 && (query.has_column?(:description) || query.has_column?(:last_notes))
              col_width = col_width.map {|w| w * (page_width - right_margin - left_margin) / table_width}
              table_width = col_width.inject(0, :+)
            end
          end
          # END PATCH

          # title
          pdf.SetFontStyle('B',11)
          pdf.RDMCell(190, 8, title)
          pdf.ln

          # totals
          totals = query.totals.map {|column, total| "#{column.caption}: #{total}"}
          if totals.present?
            pdf.SetFontStyle('B',10)
            pdf.RDMCell(table_width, 6, totals.join("  "), 0, 1, 'R')
          end

          totals_by_group = query.totals_by_group
          render_table_header(pdf, query, col_width, row_height, table_width)
          previous_group = false
          result_count_by_group = query.result_count_by_group

          issue_list(issues) do |issue, level|
            if query.grouped? &&
                (group = query.group_by_column.value(issue)) != previous_group
              pdf.SetFontStyle('B',10)
              group_label = group.blank? ? 'None' : group.to_s.dup
              group_label << " (#{result_count_by_group[group]})"
              pdf.bookmark group_label, 0, -1
              pdf.RDMCell(table_width, row_height * 2, group_label, 'LR', 1, 'L')
              pdf.SetFontStyle('',8)

              totals = totals_by_group.map {|column, total| "#{column.caption}: #{total[group]}"}.join("  ")
              if totals.present?
                pdf.RDMCell(table_width, row_height, totals, 'LR', 1, 'L')
              end
              previous_group = group
            end

            # fetch row values
            col_values = fetch_row_values(issue, query, level)

            # make new page if it doesn't fit on the current one
            base_y     = pdf.get_y
            max_height = get_issues_to_pdf_write_cells(pdf, col_values, col_width)
            space_left = page_height - base_y - bottom_margin
            if max_height > space_left
              pdf.add_page("L")
              render_table_header(pdf, query, col_width, row_height, table_width)
              base_y = pdf.get_y
            end

            # write the cells on page
            issues_to_pdf_write_cells(pdf, col_values, col_width, max_height)
            pdf.set_y(base_y + max_height)

            # START PATCH
            unless ProjectQuery.show_description_as_a_column?
              if query.has_column?(:description) && issue.description?
                pdf.set_x(10)
                pdf.set_auto_page_break(true, bottom_margin)
                pdf.RDMwriteHTMLCell(0, 5, 10, '', issue.description.to_s, issue.attachments, "LRBT")
                pdf.set_auto_page_break(false)
              end
            end
            # END PATCH

            if query.has_column?(:last_notes) && issue.last_notes.present?
              pdf.set_x(10)
              pdf.set_auto_page_break(true, bottom_margin)
              pdf.RDMwriteHTMLCell(0, 5, 10, '', issue.last_notes.to_s, [], "LRBT")
              pdf.set_auto_page_break(false)
            end
          end

          if issues.size == Setting.issues_export_limit.to_i
            pdf.SetFontStyle('B',10)
            pdf.RDMCell(0, row_height, '...')
          end
          pdf.output
          # END COPY OF STANDARD CODE
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
                    if organizations_map[project.id] && organizations_map[project.id][$1.to_i]
                      value = organizations_map[project.id][$1.to_i].uniq.join(', ')
                    else
                      value = ""
                    end
                  when /function_(\d+)$/
                    if organizations_map[project.id] && organizations_map[project.id][column.name.to_s]
                      value = organizations_map[project.id][column.name.to_s].uniq.join(', ').html_safe
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
