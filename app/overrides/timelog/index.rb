#This uses the ruby syntax for deface
#TODO: see if we can use the DSL and if it's better
Deface::Override.new :virtual_path => 'timelog/index.html',
                     :name         => 'add-crossproject-sidebar-to-timelogs-index',
                     :insert_after => 'p.pagination',
                     :text         => '<% if @project.nil? && @issue.nil?; content_for :sidebar do %><%= render "common/cross_sidebar" %><% end; end %>'
