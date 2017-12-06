class IndexForeignKeysInProjects < ActiveRecord::Migration
  def change
    add_index :projects, :default_assigned_to_id
    add_index :projects, :default_version_id
    add_index :projects, :parent_id
  end
end
