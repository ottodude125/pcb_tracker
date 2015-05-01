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
});














