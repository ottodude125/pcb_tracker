class FabIssuesController < ApplicationController
  # GET /fab_issues
  # GET /fab_issues.json
  def index
    #@fab_issues = FabIssue.all
    @design_review = ""
    if params[:design_review_id]
      @design_review = DesignReview.find(params[:design_review_id])
      @fab_issues = FabIssue.find_all_by_design_id(@design_review.design_id)
    else
      @fab_issues = FabIssue.all
    end
    
    if @fab_issues.nil?
      @fab_issues = []
    end

    # Get unique design ids with ftp date in last quarter
    today = Date.today.beginning_of_quarter - 10.days
    @begin_date = today.beginning_of_quarter
    @end_date = today.end_of_quarter
    @ftps = FtpNotification.find(:all, :conditions => ["created_at > ? AND created_at < ?", @begin_date, @end_date] )     
    @designs = @ftps.map(&:design_id).uniq
    
    # Get all fir doc/clariffication issues for ftp'd designs
    @doc_firs = FabIssue.find(:all, :conditions => ["design_id IN (?) AND documentation_issue = ?", @designs, true])
    @clr_firs = FabIssue.find(:all, :conditions => ["design_id IN (?) AND documentation_issue = ?", @designs, false])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @fab_issues }
    end
  end

  # GET /fab_issues/1
  # GET /fab_issues/1.json
  def show
    @design_review = DesignReview.find(params[:design_review_id])
    @fab_issue = FabIssue.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @fab_issue }
    end
  end

  # GET /fab_issues/new
  # GET /fab_issues/new.json
  def new
    @fab_issue = FabIssue.new
    @design_review = DesignReview.find(params[:design_review_id])
    @fab_failure_modes = FabFailureMode.order("name").find_all_by_active(true)
    fab_deliverables = FabDeliverable.order("parent_id DESC, id ASC").find_all_by_active(true)    
    @fab_deliverables = {"Other" => []}
    
    #@fab_houses = @design_review.design.fab_houses.order("name ASC")
    design_fab_houses = DesignFabHouse.where( design_id: @design_review.design_id).pluck(:fab_house_id)
    @fab_houses = FabHouse.order("name ASC").find(design_fab_houses)
    


    fab_deliverables.each do |fd|     
      # A) if fd parent id not empty then check if its parent is already in hash
      # if not add it then add fd as first item in its array otherwise just add it
      # B) if fd parent id is empty then check if fd item is already used in hash
      # if not then add it to Other
      if !fd.parent_id.nil?
        parent = FabDeliverable.find(fd.parent_id)
        if !@fab_deliverables.has_key?(parent.name)
          @fab_deliverables[parent.name] = []
        end
        @fab_deliverables[parent.name] << [fd.name, fd.id]
      else
        if !@fab_deliverables.has_key?(fd.name)
          @fab_deliverables["Other"] << [fd.name, fd.id]
        end
      end
    end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @fab_issue }
    end
  end

  # GET /fab_issues/1/edit
  def edit
    @fab_issue = FabIssue.find(params[:id])
    @design_review = DesignReview.find(params[:design_review_id])
    @fab_failure_modes = FabFailureMode.order("name").find_all_by_active(true)
    fab_deliverables = FabDeliverable.order("parent_id DESC, id ASC").find_all_by_active(true)    
    @fab_deliverables = {"Other" => []}
    #@fab_houses = @design_review.design.fab_houses.order("name ASC")
    design_fab_houses = DesignFabHouse.where( design_id: @design_review.design_id).pluck(:fab_house_id)
    @fab_houses = FabHouse.order("name ASC").find(design_fab_houses)    

    fab_deliverables.each do |fd|     
      # A) if fd parent id not empty then check if its parent is already in hash
      # if not add it then add fd as first item in its array otherwise just add it
      # B) if fd parent id is empty then check if fd item is already used in hash
      # if not then add it to Other
      if !fd.parent_id.nil?
        parent = FabDeliverable.find(fd.parent_id)
        if !@fab_deliverables.has_key?(parent.name)
          @fab_deliverables[parent.name] = []
        end
        @fab_deliverables[parent.name] << [fd.name, fd.id]
      else
        if !@fab_deliverables.has_key?(fd.name)
          @fab_deliverables["Other"] << [fd.name, fd.id]
        end
      end
    end
  end

  # POST /fab_issues
  # POST /fab_issues.json
  def create
    if params[:cleanup] == "full"
      params[:fab_issue][:full_rev_reqd] = true
      params[:fab_issue][:bare_brd_change_reqd] = false
    elsif params[:cleanup] == "bareboard"
      params[:fab_issue][:full_rev_reqd] = false
      params[:fab_issue][:bare_brd_change_reqd] = true
    else
      params[:fab_issue][:full_rev_reqd] = false
      params[:fab_issue][:bare_brd_change_reqd] = false
    end
    if (params[:fab_issue][:resolved].to_i == 1) && params[:fab_issue][:resolved_on].blank?
      params[:fab_issue][:resolved_on] = Date.today
    end

    @fab_issue = FabIssue.new(params[:fab_issue])

    respond_to do |format|
      if @fab_issue.save
        #format.html { redirect_to fab_issues_url(:design_review_id => params[:design_review][:id]), notice: 'Fab issue was successfully created.' }
        format.html { redirect_to session[:return_to], notice: 'Fab issue was successfully created.' }
        
        format.json { render json: @fab_issue, status: :created, location: @fab_issue }
      else
        format.html { render action: "new" }
        format.json { render json: @fab_issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /fab_issues/1
  # PUT /fab_issues/1.json
  def update
    @fab_issue = FabIssue.find(params[:id])

    if params[:cleanup] == "full"
      params[:fab_issue][:full_rev_reqd] = true
      params[:fab_issue][:bare_brd_change_reqd] = false
    elsif params[:cleanup] == "bareboard"
      params[:fab_issue][:full_rev_reqd] = false
      params[:fab_issue][:bare_brd_change_reqd] = true
    else
      params[:fab_issue][:full_rev_reqd] = false
      params[:fab_issue][:bare_brd_change_reqd] = false
    end
    if (params[:fab_issue][:resolved].to_i == 1) && params[:fab_issue][:resolved_on].blank?
      params[:fab_issue][:resolved_on] = Date.today
    end

    respond_to do |format|
      if @fab_issue.update_attributes(params[:fab_issue])
        #format.html { redirect_to fab_issues_url(:design_review_id => params[:design_review][:id]), notice: 'Fab issue was successfully updated.' }
        format.html { redirect_to session[:return_to], notice: 'Fab issue was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @fab_issue.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /fab_issues/1
  # DELETE /fab_issues/1.json
  def destroy
    @fab_issue = FabIssue.find(params[:id])
    @fab_issue.destroy

    respond_to do |format|
      format.html { redirect_to session[:return_to], notice: 'Fab issue was successfully deleted.' }
      format.json { head :no_content }
    end
  end
end
