class ProjectSummary
  attr_reader :project_ids

  def initialize(project_ids)
    @project_ids = project_ids
  end

  def users_count
    @users ||= Member.where("project_id in (?)", project_ids)
                     .joins(:user).where("#{Principal.table_name}.status = 1")
                     .group("project_id")
                     .count
  end

  def issues_open_count
    @open ||= Issue.where("project_id in (?)", project_ids)
                   .open.group("project_id")
                   .count
  end

  def issues_closed_count
    @closed ||= Issue.where("project_id in (?)", project_ids)
                     .open(false).group("project_id")
                     .count
  end

  def activity_period_months
    6
  end

  def activity_period_begin
    Date.today - activity_period_months.months
  end

  def activity_period
    Date.today - activity_period_begin
  end

  def activity_records
    return @records if @records
    @records = Issue.select("created_on, project_id").where("created_on > ? and project_id in (?)",
                                                            activity_period_begin, project_ids)
    @records += Journal.select("#{Journal.table_name}.created_on, project_id").joins(:issue)
                       .where("notes is not null and #{Journal.table_name}.created_on > ? and project_id in (?)",
                              activity_period_begin, project_ids)
    @records
  end

  def activity_statistics
    return @stats if @stats
    @stats = project_ids.inject({}) do |memo,project_id|
      memo[project_id] = [0]*(activity_period/7).ceil
      memo
    end
    activity_records.each do |record|
      id = record.project_id
      n = ((record.created_on.to_date - activity_period_begin) / 7).to_i
      @stats[id][n] += 1 if @stats[id] && @stats[id][n]
    end
    @stats
  end

  def self.sql_activity_records
    summary = self.new(1)
    journals = Journal.select('count(journals.*)').joins(:issue)
      .where("notes is not null and #{Journal.table_name}.created_on > ? and project_id in (projects.id)", summary.activity_period_begin).to_sql
    issues = Issue.select('count(issues.*)').where('created_on > ? and project_id in (projects.id)', summary.activity_period_begin).to_sql
    "(select (#{journals}) + (#{issues}))"
  end

end
