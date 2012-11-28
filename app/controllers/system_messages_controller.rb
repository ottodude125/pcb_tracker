class SystemMessagesController < ApplicationController
  # GET /system_messages
  # GET /system_messages.json
  def index
    @system_messages = SystemMessage.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @system_messages }
    end
  end

  # GET /system_messages/1
  # GET /system_messages/1.json
  def show
    @system_message = SystemMessage.find(params[:id])
    @type = @system_message.message_type    
    @return_url = "/pcbtr/system_messages"
    
    if params[:url_return] != nil
      @return_url = params[:url_return]
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @system_message }
    end
  end

  # GET /system_messages/new
  # GET /system_messages/new.json
  def new
    @system_message = SystemMessage.new
    @types = SystemMessage.type_list
    
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @system_message }
    end
  end

  # GET /system_messages/1/edit
  def edit
    @system_message = SystemMessage.find(params[:id])
    @types = SystemMessage.type_list
  end

  # POST /system_messages
  # POST /system_messages.json
  def create
    params[:system_message][:message_type] = SystemMessage.type_name(params[:system_message][:message_type].to_i)
    if @logged_in_user
      params[:system_message][:user_id] = @logged_in_user.id
    end
    @system_message = SystemMessage.new(params[:system_message])
    
    respond_to do |format|
      if @system_message.save
        format.html { redirect_to @system_message, notice: 'System message was successfully created.' }
        format.json { render json: @system_message, status: :created, location: @system_message }
      else
        format.html { render action: "new" }
        format.json { render json: @system_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /system_messages/1
  # PUT /system_messages/1.json
  def update
    params[:system_message][:message_type] = SystemMessage.type_name(params[:system_message][:message_type].to_i)
    if @logged_in_user
      params[:system_message][:user_id] = @logged_in_user.id
    end
    @system_message = SystemMessage.find(params[:id])

    respond_to do |format|
      if @system_message.update_attributes(params[:system_message])
        format.html { redirect_to @system_message, notice: 'System message was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @system_message.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /system_messages/1
  # DELETE /system_messages/1.json
  def destroy
    @system_message = SystemMessage.find(params[:id])
    @system_message.destroy

    respond_to do |format|
      format.html { redirect_to system_messages_url }
      format.json { head :no_content }
    end
  end
  
  # GET /changelog
  # GET /changelog.json
  def changelog
    @system_messages = SystemMessage.changelog_messages

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @system_messages }
    end
  end
      
  # GET /maintenance
  # GET /maintenance.json
  def maintenance
    @system_messages = SystemMessage.maintenance_messages

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @system_messages }
    end
  end
  
  # POST /dismiss_messages
  # POST /dismiss_messages.json
  def dismiss_messages
    respond_to do |format|
      if @logged_in_user.update_column(:message_seen, Time.now)
        format.html { redirect_to :root, notice: 'Congrats you dismissed a message.' }
        format.json { head :no_content }
      else
        format.html { redirect_to :root, notice: 'Oh Boy!! Looks like your not dismissing that message today!! Better get help.' }
        format.json { render json: @logged_in_user.errors, status: :unprocessable_entity }
      end
    end
  end
end








