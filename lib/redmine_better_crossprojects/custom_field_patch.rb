require_dependency 'custom_field'

class CustomField < ActiveRecord::Base
  unless instance_methods.include?(:visibility_by_project_condition_with_project_custom_field)
    def visibility_by_project_condition_with_project_custom_field(project_key=nil, user=User.current, id_column=nil)
      if self.class.customized_class==Project
        "1=1"
      else
        visibility_by_project_condition_without_project_custom_field(project_key, user, id_column)
      end
    end
    alias_method_chain :visibility_by_project_condition, :project_custom_field
  end
end
