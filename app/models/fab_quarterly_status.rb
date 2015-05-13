class FabQuarterlyStatus < ActiveRecord::Base
  #attr_accessible :image_name, :quarter, :status_note, :year
  
  FAB_STAT_IMAGES = ["black_delete.png", 
                      "black_edit.png", 
                      "black_view.png",
                      "N/A"]
end
