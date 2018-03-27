require_dependency 'custom_field'

module PluginBetterCrossProjects
  module CustomField
    def visibility_by_project_condition(project_key=nil, user=User.current, id_column=nil)
      if self.class.customized_class==Project
        "1=1"
      else
        super
      end
    end
  end
end

CustomField.prepend PluginBetterCrossProjects::CustomField
