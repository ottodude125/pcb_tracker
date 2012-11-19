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

    
    # Provide a formatted timestamp
    #
    # :call-seq:
    #   format_dd_mon_yy(boolean) -> String
    #
    # Returns a formatted string that represents the date with an
    # optional timestamp.
    #
    # Format of string:
    #
    #    if argument is FALSE:    dd-mon-yy
    #    if argument is TRUE:     dd-mon-yy, hh:mmm [AM|PM] TZ
    #
    #        where:    dd  - 2 digit number representing the day of the month
    #                  mon - 3 character abbreviation for the month
    #                  yy  - 2  digit number representing the year
    #                  hh  - 2 digit number representing the hour
    #                  mm  - 2 digit number representing the minutes
    #                  TZ  - Time Zone
    #
    # Example:         18-Apr-09
    #                  18-Apr-09, 07:14 AM
    #
    def format_dd_mon_yy(timestamp=false)
      result  = self.strftime("%d-%b-%y")
      result += self.strftime(", %I:%M %p") if timestamp
      result += self.localtime.strftime(" %Z") if timestamp
      result
    end


    # Provide a formatted timestamp
    #
    # :call-seq:
    #   format_month_dd_yyyy
    #
    # Returns a formatted string that represents the date.
    #
    # Format of string:
    #
    #    month dd, yyyy
    #
    #        where:    month - the unabreviated month in English
    #                  dd    - 2 digit number representing the day of the month
    #                  yyyy  - 4  digit number representing the year
    #
    # Example:         April 18, 09
    #
    def format_month_dd_yyyy
      self.strftime("%B %d, %Y")
    end


    # Provide a formatted timestamp
    #
    # :call-seq:
    #   format_dd_mm_yy_at_timestamp
    #
    # Returns a formatted string that represents the date.
    #
    # Format of string:
    #
    #    month dd, yyyy at hh:mm [AM|PM] TZ
    #
    #        where:    month - the unabreviated month in English
    #                  dd    - 2 digit number representing the day of the month
    #                  yyyy  - 4  digit number representing the year
    #                  hh  - 2 digit number representing the hour
    #                  mm  - 2 digit number representing the minutes
    #                  TZ  - Time Zone
    #
    # Example:         18-Apr-09 at 11:23 AM EST
    #
    def format_dd_mm_yy_at_timestamp
     result =  self.strftime("%d-%b-%y at %I:%M %p")
     result += self.localtime.strftime(" %Z")
    end


    # Provide a formatted timestamp
    #
    # :call-seq:
    #   format_day_mon_dd_yyyy_at_timestamp
    #
    # Returns a formatted string that represents the date.
    #
    # Format of string:
    #
    #    day mon dd, yyyy @ hh:mm [AM|PM] TZ
    #
    #        where:    month - the unabreviated month in English
    #                  dd    - 2 digit number representing the day of the month
    #                  yyyy  - 4  digit number representing the year
    #                  hh  - 2 digit number representing the hour
    #                  mm  - 2 digit number representing the minutes
    #                  TZ  - Time Zone
    #
    # Example:         Tue Jan 27, 2009 @ 11:30 AM EST
    #
    def format_day_mon_dd_yyyy_at_timestamp
      result = self.strftime("%a %b %d, %Y @ %I:%M %p")
      result += self.localtime.strftime(" %Z") 
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