require 'spec_helper'

describe QueriesHelper do
  it "should display parent column as a link to a project" do
    query = ProjectQuery.new(:name => '_', :column_names => ["name", "parent"])
    content = column_content(QueryColumn.new(:parent), query.projects.select{|e| e.parent_id == 1}.first)
    content.should have_link("eCookbook")
  end
end
