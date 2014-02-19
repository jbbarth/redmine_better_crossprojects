require File.expand_path('../../test_helper', __FILE__)

class ProjectsControllerTest < ActionController::TestCase

  self.fixture_path = File.dirname(__FILE__) + "/../fixtures/"
  fixtures :queries

  def setup
    User.current = nil
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
    get :index, :query_id => 1
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:projects)
    assert_nil assigns(:project_count_by_group)
  end

  def test_index_with_query_grouped
    get :index, :query_id => 2
    assert_response :success
    assert_template 'index'
    assert_not_nil assigns(:projects)
    assert_not_nil assigns(:project_count_by_group)
  end

  def test_index_with_query_id_should_set_session_query
    get :index, :query_id => 1
    assert_response :success
    assert_kind_of Hash, session[:project_query]
    assert_equal 1, session[:project_query][:id]
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
    get :index, :query_id => 2, :format => 'pdf'
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
