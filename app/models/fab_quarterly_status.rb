class FabQuarterlyStatus < ActiveRecord::Base
  #attr_accessible :image_name, :quarter, :status_note, :year
  
  FAB_STAT_IMAGES = ["gold_star.png", 
                      "traffic_light.png", 
                      "N/A"]
end
