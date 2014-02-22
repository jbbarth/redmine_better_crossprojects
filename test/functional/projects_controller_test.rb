require File.expand_path('../../test_helper', __FILE__)
require 'redmine_better_crossprojects/projects_controller_patch'

class ProjectsControllerTest < ActionController::TestCase

  # In this test we don't use fixtures voluntarily for ProjectQuery's
  #
  # If we want to use fixtures, we'd have to set a specific fixture_path,
  # which would prevent us from declaring explicitly all needed fixtures
  # because Rails only have one fixture directory. If we don't declare all
  # fixtures explicitly, 1/ we cannot run this test file alone and 2/ it may 
  # break depending on which other tests ran before.
  #
  # Actually it DOES break when running with all other plugins when other
  # queries fixtures have been loaded for other plugins. And if we completely
  # replace queries in core, it breaks core's tests.
  #
  # Hence the best solution for now is to generate needed fixtures here in the
  # setup phase.

  def setup
    # reset current user
    User.current = nil
    # create some useful ProjectQuery's
    @query_1 = ProjectQuery.create!(
      :name => "Query1", :user_id => 2,
      :filters => { :status => { :values => ["1"], :operator => "!" } },
      :column_names => [ "name", "status" ]
    )
    @query_2 = ProjectQuery.create!(
      :name => "Query2", :user_id => 1,
      :filters => { :status => { :values => ["1"], :operator => "=" } },
      :column_names => [], :sort_criteria => [ "name", "desc" ],
      :group_by => "status"
    )
  end

  def teardown
    # delete project queries so they don't interfer with other tests
    ProjectQuery.destroy_all
  end

  def test_index_with_default_filter
    get :index, :set_filter => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:projects)

    query = assigns(:query)
    assert_not_nil query
    # default filter
    assert_equal({'status' => {:operator => '=', :values => ['1']}}, query.filters)
  end

  def test_index_with_filter
    get :index, :set_filter => 1,
        :f => ['is_public'],
        :op => {'is_public' => '='},
        :v => {'is_public' => ['0']}
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:projects)

    query = assigns(:query)
    assert_not_nil query
    assert_equal({'is_public' => {:operator => '=', :values => ['0']}}, query.filters)
  end

  def test_index_with_empty_filters
    get :index, :set_filter => 1, :fields => ['']
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:projects)

    query = assigns(:query)
    assert_not_nil query
    # no filter
    assert_equal({}, query.filters)
  end

  def test_index_with_query
    get :index, :query_id => @query_1.id
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:projects)
    assert_nil assigns(:project_count_by_group)
  end

  def test_index_with_query_grouped
    get :index, :query_id => @query_2.id
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:projects)
    assert_not_nil assigns(:project_count_by_group)
  end

  def test_index_with_query_id_should_set_session_query
    get :index, :query_id => @query_1.id
    assert_response :success
    assert_kind_of Hash, session[:project_query]
    assert_equal @query_1.id, session[:project_query][:id]
  end

  def test_index_with_invalid_query_id_should_respond_404
    get :index, :query_id => 999
    assert_response 404
  end

  def test_index_with_query_in_session_should_show_projects
    q = ProjectQuery.create!(:name => "test", :user_id => 2)
    @request.session[:project_query] = {:id => q.id}

    get :index
    assert_response :success
    assert_not_nil assigns(:query)
    assert_equal q.id, assigns(:query).id
  end

  def test_index_csv_with_all_columns
    get :index, :format => 'csv', :columns => 'all'
    assert_response :success
    assert_not_nil assigns(:projects)
    assert_equal 'text/csv; header=present', @response.content_type
    lines = response.body.chomp.split("\n")
    assert_equal assigns(:query).available_inline_columns.size, lines[0].split(',').size
  end

  def test_index_pdf_with_query_grouped_by_status
    get :index, :query_id => @query_2.id, :format => 'pdf'
    assert_response :success
    assert_not_nil assigns(:projects)
    assert_not_nil assigns(:project_count_by_group)
    assert_equal 'application/pdf', @response.content_type
  end

  def test_index_with_columns
    columns = ['name', 'status', 'created_on']
    get :index, :set_filter => 1, :c => columns
    assert_response :success

    # query should use specified columns
    query = assigns(:query)
    assert_kind_of ProjectQuery, query
    assert_equal columns, query.column_names.map(&:to_s)

    # columns should be stored in session
    assert_kind_of Hash, session[:project_query]
    assert_kind_of Array, session[:project_query][:column_names]
    assert_equal columns, session[:project_query][:column_names].map(&:to_s)
  end

end
