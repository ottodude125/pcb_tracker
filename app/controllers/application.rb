# The filters added to this controller will be run for all controllers in the application.
# Likewise will all the methods added be available for all controllers.

require_dependency "login_system"

class ApplicationController < ActionController::Base

  include LoginSystem
  model :user

  before_filter :login_required, :only => [:append,
                                           :copy, 
                                           :destroy,
                                           :edit,
                                           :insert,
                                           :modify_checks,
                                           :move_down,
                                           :move_up, 
                                           :release]



  def paginate_collection(collection, options ={})
    default_options = {:per_page => 15, :page => 1}
    options = default_options.merge options

    pages = Paginator.new(self,
                          collection.size, 
                          options[:per_page],
                          options[:page])
    first = pages.current.offset
    last  = [first + options[:per_page], collection.size].min
    slice = collection[first...last]
    return [pages, slice]
  end

  private

  def verify_admin_role
    unless session[:active_role] == 'Admin'
      flash['notice'] = Pcbtr::MESSAGES[:admin_only]
      redirect_to(:controller => 'tracker',
                  :action     => "index")
    end
  end

end
