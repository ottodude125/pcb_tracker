########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: core_extensions.rb
#
# This library module is a collection of extensions to Ruby core types.
#
# $Id$
#
########################################################################
module CoreExtensions
  
  
  ######################################################################
  Time.class_eval do
  ######################################################################

    
    # Provide the time in the dd-mm-yy format.
    # 
    # :call-seq:
    #   simpla_date -> String
    #
    # Returns a formatted string the represents the date.
    def simple_date
      self.strftime("%d-%b-%y")
    end


    # Provide the time in the dd-mm-yy format.
    #
    # :call-seq:
    #   simpla_date_with_timestamp -> String
    #
    # Returns a formatted string the represents the date.
    def simple_date_with_timestamp
      self.strftime("%d-%b-%y, %I:%M %p")
    end
    
  end
  
  
  ######################################################################
  Float.class_eval do
  ######################################################################
   
    
    # Round the floating point number to the number of digits represented by 
    # the argument passed in.
    # 
    # :call-seq:
    #   round_to(x) -> Float
    #
    # Returns the rounded floating point number.
    def round_to(x)
      (self * 10**x).round.to_f / 10**x
    end
    
    
    # Round the floating point number to the nearest half.
    # 
    # :call-seq:
    #   round_to_half -> Float
    #
    # Returns the rounded floating point number.
    def round_to_half
      fraction = ((self - self.floor) * 100).to_i
      if fraction < 25
        self.floor.to_f
      elsif fraction < 75
        self.floor + 0.5
      else
        self.ceil.to_f
      end
    end
    
    
    # Floating point ceiling
    # 
    # :call-seq:
    #   ceil_to(x) -> Float
    #
    # Returns the ceiling for the floating point number.
    def ceil_to(x)
      (self * 10**x).ceil.to_f / 10**x
    end
    
    
    # Floating point floor
    # 
    # :call-seq:
    #   floor_to(x) -> Float
    #
    # Returns the floor for the floating point number.
    def floor_to(x)
      (self * 10**x).floor.to_f / 10**x
    end
    
  end
  
end