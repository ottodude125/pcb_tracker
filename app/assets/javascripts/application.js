// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require jquery.ui.all
//= require jquery.ui.dialog
//= require jquery.ui.datepicker
//= require dataTables/jquery.dataTables
//= require_directory ./external
//= require ./jchartfx745596/jchartfx.system.js
//= require ./jchartfx745596/jchartfx.coreVector.js
//= require ./jchartfx745596/jchartfx.advanced.js
//= require_directory .


// Function to display current time. Used in layout to display time at top of display
function ShowTime()
{
    var dt = new Date();
    $('#current_time').text(dt.toLocaleDateString() + " " + dt.toLocaleTimeString());
    window.setTimeout("ShowTime()", 1000);
}


//sets where the focus (cursor) is placed when a page loads
function setFocus() {
  if (document.forms.length > 0) {
    var field = document.forms[0];
    for (i = 0; i < field.length; i++) {
      if ((field.elements[i].type == "text") ||
          (field.elements[i].type == "textarea") ||
          (field.elements[i].type.toString().charAt(0) == "s")) {
        document.forms[0].elements[i].focus();
        break;
      }
    }
  }
}

$(document).ready(function(){
    $('textarea').autosize({className:'mirroredText'});
});

$(document).ready(function() {
	  $('.user_select').change( function() {
	      userid  = this.value;
	      url = $('#user').attr('action');
	      role = this.name;
	      //alert(url + " - " + userid + " - " + this.name)
	      $.post( url, { user_id: userid, mode: this.id, id: role},
	         function(data) {
	           var $response = $(data);
	           //update the two select lists data
	           var content = $response.find('#remove_user').html();
	           $('#remove_user').empty().append(content);
	           var content = $response.find('#add_user').html();
	           $('#add_user').empty().append(content);
	         }
	     );
	  });

	  $(".part_num_input:input").change(function() {
		  var count, value;// number of times num appears on page, value of num just entered
		  $(".part_number_error").empty();
		  $(".part_number_error").hide();
		  $(this).val($(this).val().toLocaleUpperCase());
		  $(this).removeClass("highlight");
		  count = 0;
		  value = $(this).val();
		  // count how many times the number appears on the page. If more than once its a duplicate
		  $(".part_num_input").each(function() {
		    if ($(this).val() === value) {
		      return count += 1;
		    }
		  });
		  // if num used more than once on board highlight cell and tell user
		  if (count > 1) {
		    $(this).addClass("highlight");
		    $(".part_number_error").show();
		    return $(".part_number_error").append(" ERROR: You have used " + value + " more than once on this page. ");
		  }
	  	  if ($.inArray(value, part_nums) > -1) {
	        $(this).addClass("highlight");
	        $(".part_number_error").show();
	        $(".part_number_error").append(" ERROR: " + value + " has already been used as a Part # on another board.");
	      }
		});
	  //############## MULTIPLE CHECKS ON PAGE SUBMIT  ###############
	  // 1) PCB Number is set
	  // 2) PCB number is unique
	  // 3) PCB/PCBA number is not used more than once on this board
	  $("#part_num_form_submit").click(function(event) {
		  var duplicate_number, stop_submit;
		  stop_submit = false;
		  $(".part_number_error").empty();
		  $(".part_number_error").hide();
		  $(".pcb").removeClass("highlight");
		  // 1) Check that a PCB Number has been created. If not highlight field, remove submit animation, and stop submit
		  if ($(".pcb").val() === '') {
		    $(".pcb").addClass("highlight");
		    stop_submit = true;
		    $(".part_number_error").show();
		    $(".part_number_error").append(" ERROR: PCB Number cannot be empty. <br>");
		  }
		  
		  // 2) Make sure PCB/PCBA number has not been used as a number on another board already 
		  // 3) Make sure PCB/PCBA number is not used more than once on this board
		  duplicate_number = false;
		  $(".part_num_input:input").each(function() {
		    var addedclass, count, value;
		    value = $(this).val();
		    if(value) {
			    $(this).removeClass("highlight");
			    addedclass = false;
			    count = 0;
			    value = $(this).val();
			    // count how many times the number appears on the page. If more than once its a duplicate
			    $(".part_num_input").each(function() {
			      if ($(this).val() === value) {
			        return count += 1;
			      }
			    });
			    // if num used more than once on board highlight cell, stop submit
			    if (count > 1) {
			      $(this).addClass("highlight");
			      $(".part_number_error").show();
			      duplicate_number = true;
			      stop_submit = true;
			    }
			    // check if the number was originally one of the ones assigned to this board.
			    // If it was ignore it. The user is just going back to use that number
			    if (!($.inArray(value, brd_part_nums) > -1)) {
				    // check if the number is in the pcb array of used numbers passed in from the view. if it is 
				    // then highlight the cell and stop submit because this number has already been used as a pcb         
			    	if ($.inArray(value, part_nums) > -1) {
				      $(this).addClass("highlight");
				      $(".part_number_error").show();
				      $(".part_number_error").append(" ERROR: " + value + " has already been used as a Part # on another board. <br>");
				      return stop_submit = true;
			    	}
			    }
		    }
		  });
		  if (duplicate_number) {
		    $(".part_number_error").append(" ERROR: You have used a Part # more than once on this board. <br>");
		  }
		  // FINALLY: If anything above caused an error then stop submit and hide animation
		  if (stop_submit) {
		    return event.preventDefault();
		  }
		});
});










