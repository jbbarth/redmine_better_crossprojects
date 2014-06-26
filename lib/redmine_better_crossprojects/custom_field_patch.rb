require_dependency 'custom_field'

class CustomField < ActiveRecord::Base

  def visibility_by_project_condition_with_project_key_initialization(project_key=nil, user=User.current, id_column=nil)
    if self.class.customized_class==Project
      project_key = "#{self.class.customized_class.table_name}.id"
    else
      project_key = "#{self.class.customized_class.table_name}.project_id"
    end
    visibility_by_project_condition_without_project_key_initialization(project_key)
  end
  alias_method_chain :visibility_by_project_condition, :project_key_initialization

end
