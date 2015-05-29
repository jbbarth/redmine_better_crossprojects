require 'spec_helper'
require 'redmine_better_crossprojects/queries_helper_patch'

describe QueriesHelper, type: :helper do

  it "should display parent column as a link to a project" do
    query = ProjectQuery.new(:name => '_', :column_names => ["name", "parent"])
    content = column_content(QueryColumn.new(:parent), query.projects.select{|e| e.parent_id == 1}.first)
    expect(content).to have_link("eCookbook")
  end

end
