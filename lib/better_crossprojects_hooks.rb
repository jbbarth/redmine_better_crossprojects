class BetterUiHooks < Redmine::Hook::ViewListener
  #adds our 'new issue' button logic
  #render_on :view_layouts_base_content, :partial => 'better_crossprojects/view_layouts_base_content'

  #adds our css on each page
  def view_layouts_base_html_head(context)
    javascript_include_tag("better_crossprojects", :plugin => "redmine_better_crossprojects")
  end
end
