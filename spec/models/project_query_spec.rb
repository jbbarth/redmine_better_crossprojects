require 'spec_helper'

describe "ProjectQuery" do
  fixtures :projects, :users, :members

  before do
    User.current = nil
  end

  it "should available filters should be ordered" do
    query = ProjectQuery.new
    query.available_filters.keys.index('id').should == 0
  end

  it "should project name filter in queries" do
    query = ProjectQuery.new(:name => '_')
    project_name_filter = query.available_filters["id"]
    assert_not_nil project_name_filter
    project_ids = project_name_filter[:values].map{|p| p[1]}
    assert project_ids.include?("1")  #public project
    assert !project_ids.include?("2") #private project user cannot see
  end

  def find_projects_with_query(query)
    Project.where(
        query.statement
    ).all
  end

  it "should query should allow id field for a project query" do
    project = Project.find(1)
    query = ProjectQuery.new(:name => '_')
    query.add_filter('id', '=', [project.id.to_s])
    assert query.statement.include?("#{Project.table_name}.id IN ('1')")
  end

  it "should operator none" do
    query = ProjectQuery.new(:name => '_')
    query.add_filter('id', '!*', [''])
    assert query.statement.include?("#{Project.table_name}.id IS NULL")
    find_projects_with_query(query)
  end

  it "should operator all" do
    query = ProjectQuery.new(:name => '_')
    query.add_filter('id', '*', [''])
    assert query.statement.include?("#{Project.table_name}.id IS NOT NULL")
    find_projects_with_query(query)
  end

  it "should operator is on integer custom field" do
    f = ProjectCustomField.create!(:name => 'filter', :field_format => 'int', :is_for_all => true, :is_filter => true)
    CustomValue.create!(:custom_field => f, :customized => Project.find(1), :value => '7')
    CustomValue.create!(:custom_field => f, :customized => Project.find(2), :value => '12')
    CustomValue.create!(:custom_field => f, :customized => Project.find(3), :value => '')

    query = ProjectQuery.new(:name => '_')
    query.add_filter("cf_#{f.id}", '=', ['12'])
    projects = find_projects_with_query(query)
    projects.size.should == 1
    projects.first.id.should == 2
  end

  it "should operator is not on multi list custom field" do
    f = ProjectCustomField.create!(:name => 'filter', :field_format => 'list', :is_filter => true, :is_for_all => true,
                                 :possible_values => ['value1', 'value2', 'value3'], :multiple => true)
    CustomValue.create!(:custom_field => f, :customized => Project.find(1), :value => 'value1')
    CustomValue.create!(:custom_field => f, :customized => Project.find(1), :value => 'value2')
    CustomValue.create!(:custom_field => f, :customized => Project.find(3), :value => 'value1')

    query = ProjectQuery.new(:name => '_')
    query.add_filter("cf_#{f.id}", '!', ['value1'])
    projects = find_projects_with_query(query)
    assert !projects.map(&:id).include?(1)
    assert !projects.map(&:id).include?(3)

    query = ProjectQuery.new(:name => '_')
    query.add_filter("cf_#{f.id}", '!', ['value2'])
    projects = find_projects_with_query(query)
    assert !projects.map(&:id).include?(1)
    assert projects.map(&:id).include?(3)
  end

  it "should filter member" do
    User.current = User.find(1)
    query = ProjectQuery.new(:name => '_', :filters => { 'member_id' => {:operator => '=', :values => ['me']}})
    result = find_projects_with_query(query)
    assert_not_nil result
    assert !result.empty?
  end

end
