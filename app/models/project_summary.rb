class ProjectSummary
  attr_reader :projects

  def initialize(projects)
    @projects = projects
  end

  def users_count
    @users ||= Member.where("project_id in (?)", projects)
                     .joins(:user).where("#{Principal.table_name}.status = 1")
                     .group("project_id")
                     .count
  end

  def issues_open_count
    @open ||= Issue.where("project_id in (?)", projects)
                   .open.group("project_id")
                   .count
  end

  def issues_closed_count
    @closed ||= Issue.where("project_id in (?)", projects)
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
                                                            activity_period_begin, projects.map(&:id))
    @records += Journal.select("#{Journal.table_name}.created_on, project_id").joins(:issue)
                       .where("notes is not null and #{Journal.table_name}.created_on > ? and project_id in (?)",
                              activity_period_begin, projects.map(&:id))
    @records
  end

  def activity_statistics
    return @stats if @stats
    @stats = projects.inject({}) do |memo,project|
      memo[project.id] = [0]*(activity_period/7).ceil
      memo
    end
    activity_records.each do |record|
      id = record.project_id
      n = ((record.created_on.to_date - activity_period_begin) / 7).to_i
      @stats[id][n] += 1 if @stats[id] && @stats[id][n]
    end
    @stats
  end
end
