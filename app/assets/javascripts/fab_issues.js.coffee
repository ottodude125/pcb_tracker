# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('#fab_issues_table').dataTable
    sPaginationType: "full_numbers",
    bJQueryUI: true,
    aaSorting: [[0,'desc']]


  $('#fab_issue_date_received').datepicker
    dateFormat: 'MM d, yy',
    showWeek: true,
    changeMonth: true,
    changeYear: true,
    minDate: "-1y",
    maxDate: "+2y",

  $('#fab_issue_clean_up_complete_date').datepicker
    dateFormat: 'MM d, yy',
    showWeek: true,
    changeMonth: true,
    changeYear: true,
    minDate: "-1y",
    maxDate: "+2y",
