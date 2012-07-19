require 'redmine'

require 'better_crossprojects_hooks'

# Little hack for using the 'deface' gem in redmine:
# - redmine plugins are not railties nor engines, so deface overrides in app/overrides/ are not detected automatically
# - deface doesn't support direct loading anymore ; it unloads everything at boot so that reload in dev works
# - hack consists in adding "app/overrides" path of the plugin in Redmine's main #paths
# TODO: see if it's complicated to turn a plugin into a Railtie or find something a bit cleaner
Rails.application.paths["app/overrides"] ||= []
Rails.application.paths["app/overrides"] << File.expand_path("../app/overrides", __FILE__)

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
