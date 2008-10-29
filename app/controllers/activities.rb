class Activities < Application
  RECENT_ACTIVITIES_NUM = 3
    
  before :login_required
  before :load_projects,              :only => [:new, :edit, :create]
  before :load_all_users,             :only => [:new, :edit, :create] # currently it needs to be named load_all_users 
                                                                      # instead of just load_users, because of bug 
                                                                      # (or design fault) in merb (1.0rc2) which confuses  
                                                                      # load_users with load_user
  before :load_user,                  :only => [:calendar]
  before :try_load_user,              :only => [:new] 
  before :check_calendar_viewability, :only => [:calendar]
  before :load_activity             , :only => [:destroy]
  before :check_deletable_by        , :only => [:destroy] 

  def index
    provides :csv
    @search_criteria = SearchCriteria.new(params[:search_criteria], current_user)
    @activities = @search_criteria.found_activities
    @uninvoiced_activities = @activities.reject { |a| a.invoiced? }
    @clients = Client.active.all(:order => [:name])
    @invoices = Invoice.non_issued.all(:order => [:name])
    @invoice = Invoice.new
    if content_type == :csv
      convert_to_csv(@activities)
    elsif request.xhr?
      render :index, :layout => false
    else
      render
    end
  end
  
  def new
    @activity = Activity.new(:date => Date.today, :user => current_user.is_admin? ? @user : current_user)
    render :layout => false
  end
  
  def create
    @activity = Activity.new(params[:activity])
    @activity.user = current_user unless current_user.is_admin?
    if @activity.save
      render "", :status => 201, :layout => false 
    else
      render :new, :status => 200, :layout => false
    end
  end
  
  def edit
  end
  
  def update
  end
  
  def destroy
    
  end

  # TODO refactor
  def calendar
    date = if params.has_key?("year") && params.has_key?("month")
             @year, @month = params[:year].to_i, params[:month].to_i
             { :year => @year, :month => @month }
           else
             @year, @month = Date.today.year, Date.today.month
             :this_month
           end
           
    @next_month       = @month == 12 ? 1 : @month.next
    @next_year        = @month == 12 ? @year.next : @year
    if @month == 12 && @year == Date.today.year
      @next_year      = @next_month = nil
    else
      @previous_month = @month == 1 ? 12 : @month.pred
      @previous_year  = @month == 1 ? @year.pred : @year
    end
    
    @activities = begin 
                    @user.activities.for date
                  rescue ArgumentError
                    raise BadRequest
                  end
    @activities_by_date = @activities.group_by { |activity| activity.date }
    
    if request.xhr?
      partial 'calendar_table'
    else
      render
    end
  end
  
  protected
  
  def check_deletable_by
    
  end
  
  def check_calendar_viewability
    raise Forbidden unless @user.calendar_viewable?(current_user)
  end

  def load_activity
    @activity = User.get(params[:id]) or raise NotFound
  end
  
  def load_user
    try_load_user or raise NotFound 
  end

  def try_load_user
    @user = User.get(params[:user_id])
  end
  
  def load_projects
    @recent_projects = current_user.projects.active.sort_by { |p| p.activities.recent(1).first.created_at }
    @recent_projects = @recent_projects.reverse[0...RECENT_ACTIVITIES_NUM]
    # .all(:order => ["activities.created_at DESC"], :limit => RECENT_ACTIVITIES_NUM)
    @other_projects = Project.active - @recent_projects
  end
  
  def load_all_users
    @users = Employee.active.all(:order => [:name.asc]) if current_user.is_admin?
  end
  
  def convert_to_csv(activities)
    report = StringIO.new
    CSV::Writer.generate(report, ',') do |csv|
      csv << %w(Client Project Role User Date Hours)
      activities.each do |activity|
        csv << [activity.project.client.name, activity.project.name, activity.user.role.name, activity.user.name, 
                activity.date, format("%.2f", activity.minutes / 60.0)]
      end
    end
    report.rewind
    report.read
  end
end # Activities
