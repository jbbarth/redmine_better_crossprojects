require 'spec_helper'

describe ProjectSummary do
  fixtures :projects, :members, :users,
           :issues, :issue_statuses, :journals

  let(:project_ids) { Project.pluck(:id) }
  let(:summary) { ProjectSummary.new(project_ids) }

  describe "#project_ids" do
    it "gives access to project_ids" do
      project_ids = double
      expect(ProjectSummary.new(project_ids).project_ids).to eq project_ids
    end
  end

  describe "#users_count" do
    it "aggregates users by project" do
      expect(summary.users_count[5]).to eq Project.find(5).users.count
    end
  end

  describe "#issues_open_count" do
    it "aggregates open issues by project" do
      expect(summary.issues_open_count[5]).to eq Project.find(5).issues.open.count
    end
  end

  describe "#issues_closed_count" do
    it "aggregates closed issues by project" do
      expect(summary.issues_closed_count[1]).to eq Project.find(1).issues.open(false).count
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
      summary = ProjectSummary.new([p.id])
      expect(summary.activity_statistics[p.id].uniq).to eq [0]
    end

    it "builds statistics based upon activity_records" do
      allow(summary).to receive(:project_ids) { [1] }
      allow(summary).to receive(:activity_records) {
        [double(:project_id => 1, :created_on => Date.today),
         double(:project_id => 1, :created_on => Date.today)]
      }
      expect(summary.activity_statistics[1].last).to eq 2
    end
  end
end
