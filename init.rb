require 'redmine'

Redmine::Plugin.register :redmine_better_crossprojects do
  name 'Redmine Better Crossprojects plugin'
  description 'This plugin will just provide better cross project views (based on 1.0.0(RC) ones)'
  url 'https://github.com/jbbarth/redmine_better_crossprojects'
  author 'Jean-Baptiste BARTH'
  author_url 'mailto:jeanbaptiste.barth@gmail.com'
  requires_redmine :version_or_higher => '2.0.3'
  requires_redmine_plugin :redmine_base_deface, :version_or_higher => "0.0.1"
  version '0.1'
end

Redmine::MenuManager.map :project_menu do |menu|
  #menu.delete :new_issue
end
