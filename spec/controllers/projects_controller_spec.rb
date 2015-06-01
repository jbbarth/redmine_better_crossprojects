require 'spec_helper'
require 'redmine_better_crossprojects/projects_controller_patch'

describe ProjectsController, type: :controller do
  render_views

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

  before do
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

  it "should index with default filter" do
    get :index, :set_filter => 1
    expect(response).to be_success
    assert_template 'index'
    refute_nil assigns(:projects)

    query = assigns(:query)
    refute_nil query
    # default filter
    assert_equal({'status' => {:operator => '=', :values => ['1']}}, query.filters)
  end

  it "should index with filter" do
    get :index, :set_filter => 1,
        :f => ['is_public'],
        :op => {'is_public' => '='},
        :v => {'is_public' => ['0']}
    expect(response).to be_success
    assert_template 'index'
    refute_nil assigns(:projects)

    query = assigns(:query)
    refute_nil query
    assert_equal({'is_public' => {:operator => '=', :values => ['0']}}, query.filters)
  end

  it "should index with empty filters" do
    get :index, :set_filter => 1, :fields => ['']
    expect(response).to be_success
    assert_template 'index'
    refute_nil assigns(:projects)

    query = assigns(:query)
    refute_nil query
    # no filter
    assert_equal({}, query.filters)
  end

  it "should index with query" do
    get :index, :query_id => @query_1.id
    expect(response).to be_success
    assert_template 'index'
    refute_nil assigns(:projects)
    assert_nil assigns(:project_count_by_group)
  end

  it "should index with query grouped" do
    get :index, :query_id => @query_2.id
    expect(response).to be_success
    assert_template 'index'
    refute_nil assigns(:projects)
    refute_nil assigns(:project_count_by_group)
  end

  it "should index with query id should set session query" do
    get :index, :query_id => @query_1.id
    expect(response).to be_success
    assert_kind_of Hash, session[:project_query]
    session[:project_query][:id].should == @query_1.id
  end

  it "should index with invalid query id should respond 404" do
    get :index, :query_id => 999
    assert_response 404
  end

  it "should index with query in session should show projects" do
    q = ProjectQuery.create!(:name => "test", :user_id => 2)
    @request.session[:project_query] = {:id => q.id}

    get :index
    expect(response).to be_success
    refute_nil assigns(:query)
    assigns(:query).id.should == q.id
  end

  it "should index csv with all columns" do
    get :index, :format => 'csv', :columns => 'all'
    expect(response).to be_success
    refute_nil assigns(:projects)
    @response.content_type.should == 'text/csv; header=present'
    lines = response.body.chomp.split("\n")
    lines[0].split(',').size.should == assigns(:query).available_inline_columns.size
  end

  it "should index pdf with query grouped by status" do
    get :index, :query_id => @query_2.id, :format => 'pdf'
    expect(response).to be_success
    refute_nil assigns(:projects)
    refute_nil assigns(:project_count_by_group)
    @response.content_type.should == 'application/pdf'
  end

  it "should index with columns" do
    columns = ['name', 'status', 'created_on']
    get :index, :set_filter => 1, :c => columns
    expect(response).to be_success

    # query should use specified columns
    query = assigns(:query)
    assert_kind_of ProjectQuery, query
    query.column_names.map(&:to_s).should == columns

    # columns should be stored in session
    assert_kind_of Hash, session[:project_query]
    assert_kind_of Array, session[:project_query][:column_names]
    session[:project_query][:column_names].map(&:to_s).should == columns
  end

end
