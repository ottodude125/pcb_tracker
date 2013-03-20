module RolesHelper

  # Method returns an array of users which are not assigned to a role
  def unassigned_users
    users = User.all
    assigned = @role.users.collect
    list = []
    assigned.each do |id|
      list << User.find_by_id(id)
    end
    available_users = users - list
  end
  
  # Method returns an array of groups which are assigned to a role
  def assigned_users
    assigned = @role.users.collect
    listu = []
    assigned.each do |id|
      listu << User.find_by_id(id)
    end
    listu
  end

end