########################################################################
#
# Copyright 2005, by Teradyne, Inc., Boston MA
#
# File: time_helper.rb
#
# This helper is provided to extend the Time class.
#
# $Id$
#
########################################################################

module TimeHelper
  
  
  SUNDAY   = 0
  SATURDAY = 6


  Time.class_eval do
    
    
    ######################################################################
    #
    # weekday?
    #
    # Description:
    # Determines if the object is a weekday.
    #
    # Parameters:
    # None
    #
    # Return value:
    # TRUE it the object is a weekday?,  otherwise FALSE is returned
    #
    ######################################################################
    #
    def weekday?
      day = self.strftime("%w").to_i
      (SUNDAY < day && day < SATURDAY)
    end
    
    
    ######################################################################
    #
    # start_of_quarter
    #
    # Description:
    # Generates the date for the begining of the quarter based on time
    #
    # Parameters:
    # none
    #
    # Return value:
    # A date record indicating the start of the quarter for date.
    #
    ######################################################################
    #
    def start_of_quarter
      
      year          = self.strftime('%Y').to_i
      current_month = self.strftime('%m').to_i
      
      month = 1
      1.step(13, 3) do |m|
        break if m > current_month
        month = m
      end
      
      Date.new(year, month, 1)
        
    end
    
    
    ######################################################################
    #
    # start_of_month
    #
    # Description:
    # Generates the date for the begining of the month based on time
    #
    # Parameters:
    # none
    #
    # Return value:
    # A date record indicating the start of the month for date.
    #
    ######################################################################
    #
    def start_of_month
      Date.new(self.strftime('%Y').to_i, self.strftime('%m').to_i, 1)
    end

    
    ######################################################################
    #
    # age_in_seconds
    #
    # Description:
    # This method computes the number of seconds between the start_time 
    # and the object's time excluding time on the weekend days.
    #
    # Parameters:
    # start_time - the beginning of the time interval
    #
    # Return value:
    # The number of seconds (representing work days) between the 
    # start_time and the object's time.
    #
    ######################################################################
    #
    def age_in_seconds(start_time)

      return 0 if start_time >= self
    
      # If the start time is a weekend, initialize the delta to 
      # zero.  Otherwise, initialize delta to the number of seconds
      # between the start time and midnight of the next day.
      delta = 0
      if start_time.weekday?
        midnight_tomorrow = start_time.tomorrow.midnight
        if self > midnight_tomorrow
          delta = midnight_tomorrow - start_time
        else
          delta = self - start_time
        end
      end

      # Advance start time to midnight.
      start_time = start_time.tomorrow.midnight
    
      while (self - start_time) >= 1.day
        # Only increment for a weekday
        delta      += 1.day if start_time.weekday? 
        start_time += 1.day
      end
    
      # Pick up the remaining time
      delta += self - start_time if start_time.weekday? if self > start_time
    
      delta.to_i
  
    end


    ######################################################################
    #
    # age_in_days
    #
    # Description:
    # This method returns the age of a design_review in work days
    #
    # Parameters:
    # current_time - the time stamp for the current time
    #
    # Return value:
    # A floating point number that indicates the number of days between the
    # time stored in the object and the time passed in.
    #
    ######################################################################
    #
    def age_in_days(start_time)
      (self.age_in_seconds(start_time).to_f / 1.day)
    end
    
    
    ######################################################################
    #
    # current_quarter
    #
    # Description:
    # Computes the current quarter.
    #
    # Parameters
    # None
    #
    # Return value:
    # In integer 1 through 4 that represents the current quarter.
    #
    ######################################################################
    #
    def current_quarter
  
      case self.month
    
      when 1..3: 1
      when 4..6: 2
      when 7..9: 3
      else       4
      end
    
    end


  end

  
end
