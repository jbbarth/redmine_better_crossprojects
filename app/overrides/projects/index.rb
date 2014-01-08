# encoding: utf-8
Deface::Override.new :virtual_path  => 'projects/index',
                     :name          => 'add-search-form-to-projects-index',
                     :replace  => '#projects_list_and_exports' do
  '<%= form_tag({ :controller => "projects", :action => "index" },
             :method => :get, :id => "query_form") do %>
    <%= hidden_field_tag "set_filter", "1" %>
    <div id="query_form_content" class="hide-when-print">

      <fieldset id="filters" class="collapsible <%= @query && @query.filters && !@query.filters.empty? ? "" : "collapsed" %>">
        <legend onclick="toggleFieldset(this);"><%= l(:label_filters_and_options) %></legend>
        <div style="<%= @query && @query.filters && !@query.filters.empty? ? "" : "display: none;" %>">
          <%  if @query == nil
                @query = ProjectQuery.new(:name => "_")
                @query.build_from_params(params)
              end %>
          <%= render :partial => "queries/filters", :locals => {:query => @query} %>

          <div class="query_form_options">

            <table>
              <tr>
                <td><%= l(:field_column_names) %></td>
                <td><%= render_query_columns_selection(@query) %></td>
              </tr>
              <tr>
                <td><label for="group_by"><%= l(:field_group_by) %></label></td>
                <td><%= select_tag("group_by",
                                   options_for_select(
                                     [[]] + @query.groupable_columns.collect {|c| [c.caption, c.name.to_s]},
                                     @query.group_by)
                           ) %></td>
              </tr>
              <tr>
                <td><%= l(:button_show) %></td>
                <td><%= available_block_columns_tags(@query) %></td>
              </tr>
            </table>
          </div>

          <%= link_to_function l(:button_apply), "submit_query_form(\"query_form\")", :class => "icon icon-checked" %>
          <%= link_to l(:button_clear), { :set_filter => 1 }, :class => "icon icon-reload"  %>

        </div>
      </fieldset>

    </div>

  <% end %>

  <%= render :partial => "list", :locals => {:projects => @projects} if @query %>

  <% content_for :header_tags do %>
    <%= javascript_include_tag "select_list_move" %>
  <% end %>
'
end
