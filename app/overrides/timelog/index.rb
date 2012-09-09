#This uses the ruby syntax for deface
#TODO: see if we can use the DSL and if it's better
Deface::Override.new :virtual_path => 'timelog/index',
                     :original     => 'ee65ebb813ba3bbf55bc8dc6279f431dbb405c48',
                     :name         => 'add-crossproject-sidebar-to-timelogs-index',
                     :insert_after => 'p.pagination',
                     :text         => '<% if @project.nil? && @issue.nil?; content_for :sidebar do %><%= render "common/cross_sidebar" %><% end; end %>'
