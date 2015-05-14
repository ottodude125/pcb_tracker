# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  $('#fab_issues_table').dataTable
    sPaginationType: "full_numbers",
    bJQueryUI: true,
    "iDisplayLength": 25,
    aaSorting: [[0,'desc']]

  $('#fab_issue_received_on').datepicker
    dateFormat: 'MM d, yy',
    showWeek: true,
    changeMonth: true,
    changeYear: true,
    minDate: "-1y",
    maxDate: "+2y"

  $('#fab_issue_clean_up_complete_on').datepicker
    dateFormat: 'MM d, yy',
    showWeek: true,
    changeMonth: true,
    changeYear: true,
    minDate: "-1y",
    maxDate: "+2y"
  

    
  # On page load display clean up complete row if clean up reqd checked
  #if $('#fab_issue_documentation_issue').is(':checked') 
  #    $('#clean_up_complete_row').show()      
  #    $('#fab_failure_mode_complete_row').show()      
  #  else
  #    $('#fab_issue_clean_up_complete_on').val ""
  #    $('#clean_up_complete_row').val("").hide()
  #    $('#fab_failure_mode_complete_row').val("").hide()

  # When clean up reqd is check/unchecked show/hide date row
  #$('#fab_issue_documentation_issue').click -> 
  #  if $(this).is(':checked')      
  #    $('#clean_up_complete_row').show()
  #    $('#fab_failure_mode_complete_row').show()
  #  else
  #    $('#fab_issue_clean_up_complete_on').val ""
  #    $('#clean_up_complete_row').hide()
  #    $('#fab_failure_mode_complete_row').hide()


  # On page load display clean up complete row if clean up reqd checked
  $('.fab_issue_doc_issue').each (i,obj) ->
    row_class = [
      ''
      ''
      ''
    ]
    if $(obj).is(':checked')  
      row_class = $(this).attr('class').split(' ')
      #alert('#clean_up_complete_row_' + row_class[1] + "_" + row_class[2])    
      $('#clean_up_complete_row_' + row_class[1] + "_" + row_class[2]).show()
      $('#fab_failure_mode_complete_row_' + row_class[1] + "_" + row_class[2]).show()
    else
      row_class = $(this).attr("class").split(" ")
      #alert('#fab_failure_mode_complete_row_' + row_class[1] + "_" + row_class[2])    
      $('.fab_issue_complete_on_' + row_class[1] + "_" + row_class[2]).val ""
      $('#clean_up_complete_row_' + row_class[1] + "_" + row_class[2]).hide()
      $('#fab_failure_mode_complete_row_' + row_class[1] + "_" + row_class[2]).hide()

  # When clean up reqd is check/unchecked show/hide date row
  $('.fab_issue_doc_issue').click -> 
    row_class = $(this).attr("class").split(" ")
    if $(this).is(':checked')                 
      $('#clean_up_complete_row_' + row_class[1] + "_" + row_class[2]).show()
      $('#fab_failure_mode_complete_row_' + row_class[1] + "_" + row_class[2]).show()
    else
      $('.fab_issue_complete_on_' + row_class[1] + "_" + row_class[2]).val ""
      $('#clean_up_complete_row_' + row_class[1] + "_" + row_class[2]).hide()
      $('#fab_failure_mode_complete_row_' + row_class[1] + "_" + row_class[2]).hide()
      







