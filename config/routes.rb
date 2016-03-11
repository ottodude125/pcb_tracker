########################################################################
#
# Copyright 2008, by Teradyne, Inc., North Reading MA
#
# File: routes.rb
#
# Contains the routing configuration for the PCB Design Tracker.
#
# $Id$
#
########################################################################
#
PcbTracker::Application.routes.draw do


  resources :model_types


  resources :model_comments


  resources :model_documents


  resources :model_tasks


  resources :fab_quarterly_statuses


  resources :board_design_entry do
    collection do
      get  'originator_list'
      get  'processor_list'
      get  'get_part_number'
    end
    member do
      post 'update_yes_no'
      get  'delete_entry'
    end
  end

  resources :change_classes do
    resources :change_types, :name_prefix => "change_class_"
    collection do
      get  :reason_relationships
    end
  end
  
  resources :change_items do
    resources :change_details, :name_prefix => "change_item_"
  end

  resources :change_types do
    resources :change_items, :name_prefix => "change_type_"
  end
  
  resources :design do
    member do
      post 'change_cc_list'
      post 'get_role_users'
      get  'view'
    end
    collection do
      get  'initial_cc_list'
      get  'initial_attachments'
      get  'list'
      get 'set_fir_complete'
    end
  end
  
  resources :design_changes do
    collection do
      get 'pending_list'
    end
  end

  resources :design_review do
    member do
      post 'display_peer_auditor_select'
      post 'display_designer_select'
      get  'review_mail_list'
      get  'review_attachments'
    end
    collection do
      get  'change_design_dir'
      get  'update_documents'
      get  'get_attachment'
      get  'delete_document'
      get  'change_design_center'
      get  'repost_review'
      get  'post_review'
      get  'skip_review'
   end
  end

  resources :eco_documents

  resources :eco_tasks do
    collection do
      post 'change_cc_list'
    end
  end
  
  resources :eco_task_reports

  #resources :fab_deliverables
  #resources :fab_failure_modes
  resources :fab_issues
    
  resources :part_nums

  resources :report do
    collection do
      #get 'user_review_history(.:format)'
      #get 'reviewer_approval_time(.:format)'
      #get '/reviewer_workload'
      #post 'reviewer_approval_time(.:format)'
      get 'user_review_history'
      get 'reviewer_approval_time'
      get 'reviewer_workload'
      post 'reviewer_approval_time'
      get 'summary_data'
      get 'fir_metrics'
    end
  end

  resources :roles do
    member do
      post :change_users_list
    end
  end
 
  resources :system_messages do
    collection do
      get :changelog
      get :maintenance
      get :dismiss_messages
    end
  end
  
  #match '/reports/user_review_history(.:format)' => "report#user_review_history"

  # In the event that only the root is provided in the URL,
  # display the tracker home page (index).
  root :to => 'tracker#index'

  match "_vti_bin/owssvr.dll" => 'tracker#index'
  match "MSOffice/cltreq.asp" => 'tracker#index'
  
  match "/documentation" => "documentation#index"

  # See how all your routes lay out with "rake routes"
  
  # Install the default routes as the lowest priority.
  match ':controller(/:action(/:id(.:format)))'

end
