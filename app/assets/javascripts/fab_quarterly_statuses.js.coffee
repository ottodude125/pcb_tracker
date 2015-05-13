# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('#fab_quarterly_statuses_table').dataTable
    sPaginationType: "full_numbers",
    bJQueryUI: true,
    "iDisplayLength": 25,
    aaSorting: [[1,'desc'],[0,'desc']]
