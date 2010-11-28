class PartNumsController < ApplicationController
  # GET /part_nums
  # GET /part_nums.xml
  def index
    @part_nums = PartNum.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @part_nums }
    end
  end

  # GET /part_nums/1
  # GET /part_nums/1.xml
  def show
    @part_num = PartNum.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @part_num }
    end
  end

  # GET /part_nums/new
  # GET /part_nums/new.xml
  def new
    @rows = []
    if params[:board_entry]
      @rows << PartNum.new( :use => "pcb",  :revision => "a" )
      @rows << PartNum.new( :use => "pcba", :revision => "a" )
      @rows << PartNum.new( :use => "pcba", :revision => "a" )
      @rows << PartNum.new( :use => "pcba", :revision => "a" )
      @rows << PartNum.new( :use => "pcba", :revision => "a" )
    else
      @rows << PartNum.new
    end

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @rows }
    end
  end
  # GET /part_nums/1/edit
  def edit
    @part_num = PartNum.find(params[:id])
  end

  # POST /part_nums
  # POST /part_nums.xml
  def create
    fail = 0
    @errors = []
    @rows   = []
    params[:rows].each_value do |pnum|
      num = PartNum.new(pnum)
      @rows << num
      if ! num.save
        fail = 1
        @errors << num.errors
      end
    end
 
    respond_to do |format|
      if fail == 0
        flash[:notice] = 'Part numbers was successfully created.'
        format.html { redirect_to( part_nums_path() ) }
        format.xml  { render :xml => @part_num, :status => :created, :location => @part_num }
      else
        flash[:notice] = 'Part number creation failed.'
        format.html { render :action => "new" }
        format.xml  { render :xml => @errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /part_nums/1
  # PUT /part_nums/1.xml
  def update
    @part_num = PartNum.find(params[:id])

    respond_to do |format|
      if @part_num.update_attributes(params[:part_num])
        flash[:notice] = 'PartNum was successfully updated.'
        format.html { redirect_to(@part_num) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @part_num.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /part_nums/1
  # DELETE /part_nums/1.xml
  def destroy
    @part_num = PartNum.find(params[:id])
    @part_num.destroy

    respond_to do |format|
      format.html { redirect_to(part_nums_url) }
      format.xml  { head :ok }
    end
  end
end
