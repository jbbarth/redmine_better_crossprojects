require File.expand_path('../../spec_helper', __FILE__)

describe ProjectSummary do
  fixtures :projects, :members, :users,
           :issues, :issue_statuses, :journals

  let(:projects) { Project.all }
  let(:summary) { ProjectSummary.new(projects) }

  describe "#projects" do
    it "gives access to projects" do
      projects = stub
      ProjectSummary.new(projects).projects.should == projects
    end
  end

  describe "#users_count" do
    it "aggregates users by project" do
      summary.users_count[5].should == Project.find(5).users.count
    end
  end

  describe "#issues_open_count" do
    it "aggregates open issues by project" do
      summary.issues_open_count[5].should == Project.find(5).issues.open.count
    end
  end

  describe "#issues_closed_count" do
    it "aggregates closed issues by project" do
      summary.issues_closed_count[1].should == Project.find(1).issues.open(false).count
    end
  end

  describe "#activity_records" do
    #TODO: how to test that?
  end

  describe "#activity_period" do
    #TODO: how to test that *reliably*?
  end

  describe "#activity_statistics" do
    it "initializes statistics even if project has no records" do
      p = Project.create!(:name => "Project X", :identifier => "p-x")
      summary = ProjectSummary.new([p])
      summary.activity_statistics[p.id].uniq.should == [0]
    end

    it "builds statistics based upon activity_records" do
      summary.stub(:projects) {
        [stub(:id => 1)]
      }
      summary.stub(:activity_records) {
        [stub(:project_id => 1, :created_on => Date.today),
         stub(:project_id => 1, :created_on => Date.today)]
      }
      summary.activity_statistics[1].last.should == 2
    end
  end
end
