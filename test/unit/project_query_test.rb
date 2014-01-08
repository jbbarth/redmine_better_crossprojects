require File.expand_path('../../test_helper', __FILE__)

class ProjectQueryTest < ActiveSupport::TestCase
  include Redmine::I18n

  fixtures :projects, :enabled_modules, :users, :members,
           :member_roles, :roles, :trackers, :issue_statuses,
           :issue_categories, :enumerations, :issues,
           :watchers, :custom_fields, :custom_values, :versions,
           :queries,
           :projects_trackers,
           :custom_fields_trackers

  def test_available_filters_should_be_ordered
    query = ProjectQuery.new
    assert_equal 0, query.available_filters.keys.index('id')
  end

  def test_project_name_filter_in_queries
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

  def test_query_should_allow_id_field_for_a_project_query
    project = Project.find(1)
    query = ProjectQuery.new(:name => '_')
    query.add_filter('id', '=', [project.id.to_s])
    assert query.statement.include?("#{Project.table_name}.id IN ('1')")
  end

  def test_operator_none
    query = ProjectQuery.new(:name => '_')
    query.add_filter('id', '!*', [''])
    assert query.statement.include?("#{Project.table_name}.id IS NULL")
    find_projects_with_query(query)
  end

  def test_operator_all
    query = ProjectQuery.new(:name => '_')
    query.add_filter('id', '*', [''])
    assert query.statement.include?("#{Project.table_name}.id IS NOT NULL")
    find_projects_with_query(query)
  end

  def test_operator_is_on_integer_custom_field
    f = ProjectCustomField.create!(:name => 'filter', :field_format => 'int', :is_for_all => true, :is_filter => true)
    CustomValue.create!(:custom_field => f, :customized => Project.find(1), :value => '7')
    CustomValue.create!(:custom_field => f, :customized => Project.find(2), :value => '12')
    CustomValue.create!(:custom_field => f, :customized => Project.find(3), :value => '')

    query = ProjectQuery.new(:name => '_')
    query.add_filter("cf_#{f.id}", '=', ['12'])
    projects = find_projects_with_query(query)
    assert_equal 1, projects.size
    assert_equal 2, projects.first.id
  end

  def test_operator_is_not_on_multi_list_custom_field
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

  def test_filter_member
    User.current = User.find(1)
    query = ProjectQuery.new(:name => '_', :filters => { 'member_id' => {:operator => '=', :values => ['me']}})
    result = find_projects_with_query(query)
    assert_not_nil result
    assert !result.empty?
    User.current = nil
  end

end
