# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('#log_table').dataTable
    sPaginationType: "full_numbers"
    bJQueryUI: true
    aaSorting: [[0,'desc']]
    
  $('#system_message_valid_from').datepicker
    dateFormat: 'MM d, yy',
    showWeek: true,
    changeMonth: true,
    changeYear: true,
    minDate: 0,
    onClose: (selectedDate) ->
      $("#system_message_valid_until").datepicker "option", "minDate", selectedDate
    
  $('#system_message_valid_until').datepicker
    dateFormat: 'MM d, yy',
    showWeek: true,
    changeMonth: true,
    changeYear: true,
    minDate: 0,
    maxDate: "+20y",
    onClose: (selectedDate) ->
      $("#system_message_valid_from").datepicker "option", "maxDate", selectedDate



