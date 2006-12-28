########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: oi_category.rb
#
# This file maintains the state for oi_categories.
#
# $Id$
#
########################################################################

class OiCategory < ActiveRecord::Base

  has_many :oi_category_sections

end
