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
ActionController::Routing::Routes.draw do |map|

  map.resources :change_classes do |change_classes|
    change_classes.resources :change_types, :name_prefix => "change_class_"
  end
  
  map.resources :change_types do |change_types|
    change_types.resources :change_items, :name_prefix => "change_type_"
  end
  
  map.resources :change_items do |change_items|
    change_items.resources :change_details, :name_prefix => "change_item_"
  end
   
  #map.resources :change_details
  #map.resources :change_items
  #map.resources :change_class, :has_many => :change_types
  map.resources :eco_tasks
  map.resources :eco_task_reports
  map.resources :eco_documents

  
  
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # In the event that only the root is provided in the URL,
  # display the tracker home page (index).
  map.root :controller => 'tracker', :action => 'index'

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
