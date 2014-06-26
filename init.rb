require 'redmine'
require 'redmine_better_crossprojects/deface_patch'

ActionDispatch::Callbacks.to_prepare do
  require_dependency 'redmine_better_crossprojects/projects_controller_patch' unless Rails.env.test?
  require_dependency 'redmine_better_crossprojects/custom_field_patch'
end

# Little hack for using the 'deface' gem in redmine:
# - redmine plugins are not railties nor engines, so deface overrides in app/overrides/ are not detected automatically
# - deface doesn't support direct loading anymore ; it unloads everything at boot so that reload in dev works
# - hack consists in adding "app/overrides" path of the plugin in Redmine's main #paths
# TODO: see if it's complicated to turn a plugin into a Railtie or find something a bit cleaner
Rails.application.paths["app/overrides"] ||= []
Rails.application.paths["app/overrides"] << File.expand_path("../app/overrides", __FILE__)

Redmine::Plugin.register :redmine_better_crossprojects do
  name 'Redmine Better Crossprojects plugin'
  description 'This plugin will just provide better cross project views (based on 1.0.0(RC) ones)'
  url 'https://github.com/jbbarth/redmine_better_crossprojects'
  author 'Jean-Baptiste BARTH'
  author_url 'mailto:jeanbaptiste.barth@gmail.com'
  requires_redmine :version_or_higher => '2.0.3'
  requires_redmine_plugin :redmine_base_select2, :version_or_higher => '0.0.1'
  requires_redmine_plugin :redmine_base_rspec, :version_or_higher => '0.0.1'
  version '0.2'
  settings :default => { 'default_columns' => "name,role,users,issues,activity", 'show_description_as_a_column' => true },
           :partial => 'settings/redmine_plugin_better_crossprojects_settings'
end

Redmine::MenuManager.map :project_menu do |menu|
  #menu.delete :new_issue
end
