// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require dataTables/jquery.dataTables
//= require_tree .


// Function to display current time. Used in layout to display time at top of display
function ShowTime()
{
    var dt = new Date();
    $('#current_time').text(dt.toLocaleDateString() + " " + dt.toLocaleTimeString());
    window.setTimeout("ShowTime()", 1000);
}


//dynamic text area which grows the more a person types
function init_textarea(comment_field) {
if ( !document.getElementById)
  return;
document.getElementById(comment_field).rows=5;
document.getElementById(comment_field).onkeyup = textarea_grow(5);
};


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


