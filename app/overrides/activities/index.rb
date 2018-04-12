#This uses the ruby syntax for deface
#TODO: see if we can use the DSL and if it's better
Deface::Override.new :virtual_path => 'activities/index',
                     :original     => '0b749d9eec363aebe78c455314e5d87f02ab72a2',
                     :name         => 'add-crossproject-sidebar-to-activities-index',
                     :replace      => 'h3:contains("label_activity")',
                     :text         => '<%= @project ? content_tag(:h3, l(:label_activity)) : render("common/cross_sidebar") %>'
