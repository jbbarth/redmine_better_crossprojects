#This uses the ruby syntax for deface
#TODO: see if we can use the DSL and if it's better
Deface::Override.new :virtual_path => 'activities/index',
                     :original     => 'd3fb826a2bd63adc1df8f1fd9d6bd3706a548bab',
                     :name         => 'add-crossproject-sidebar-to-activities-index',
                     :replace      => 'h3:contains("label_activity")',
                     :text         => '<%= @project ? content_tag(:h3, l(:label_activity)) : render("common/cross_sidebar") %>'
