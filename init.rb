require 'redmine'

require 'better_crossprojects_hooks'

Redmine::Plugin.register :redmine_better_crossprojects do
  name 'Redmine Better Crossprojects plugin'
  author 'Jean-Baptiste BARTH'
  description 'This plugin will just provide better cross project views (based on 1.0.0(RC) ones)'
  author_url 'mailto:jeanbaptiste.barth@gmail.com'
  requires_redmine :version_or_higher => '2.0.3'
  version '0.1'
end

Redmine::MenuManager.map :project_menu do |menu|
  #menu.delete :new_issue
end
