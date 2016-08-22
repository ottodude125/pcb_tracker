# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

jQuery ->
  
  
  # Check form filled out correctly
  $('#bde_details_submit').click (event) ->
    prevent_submit = 0

    #### Check If Division Selected ####
    $("#division_required").text(" required")
    if $('#board_design_entry_division_id').val() == '0'
      prevent_submit = 1
      $("#division_required").text(' Please Select Division')

    #### Check If Location Selected ####
    $("#location_required").text(" required")
    if $('#board_design_entry_location_id').val() == '0'
      prevent_submit = 1
      $("#location_required").text(' Please Select Location')
      
    #### Check If Platform Selected ####
    $("#platform_required").text(" required")
    if !$('#board_design_entry_platform_id').val()
      prevent_submit = 1
      $("#platform_required").text(' Please Select Platform')
      
    #### Check If Project Selected ####
    $("#project_required").text(" required")
    if !$('#board_design_entry_project_id').val()
      prevent_submit = 1
      $("#project_required").text(' Please Select Project')
      
    #### Check If Product Selected ####
    $("#product_type_required").text(" required")
    if !$('#board_design_entry_product_type_id').val()
      prevent_submit = 1
      $("#product_type_required").text(' Please Select Product Type')

    #### Check If Make From Selected YES ####
    $('#orig_pcb_num_error').hide()
    mkfrm_stat = $('input[name="board_design_entry[make_from]"]:checked').val()
    # Set to yes - check if orig pcb number entered 
    if mkfrm_stat == '1'
      orig_pcb_num = $("#board_design_entry_original_pcb_number").val()
      if !orig_pcb_num # inform user desc required and prevent submit
        prevent_submit = 1
        $('#orig_pcb_num_error').show()
    else # If unchecked set description to empty string
      $("#board_design_entry_original_pcb_number").val("")

    #### Check If Backplane Selected YES ####
    $('#purchased_assy_num_error').hide()
    back_stat = $('input[name="board_design_entry[backplane]"]:checked').val()
    # Set to yes - check if orig pcb number entered 
    if back_stat == '1'
      pur_assy_num = $("#board_design_entry_purchased_assembly_number").val()
      if !pur_assy_num # inform user desc required and prevent submit
        prevent_submit = 1
        $('#purchased_assy_num_error').show()
    else # If unchecked set description to empty string
      $("#board_design_entry_purchased_assembly_number").val("")

    #### Check If Voltage Selected YES ####
    $('#exceed_voltage_details_error').hide()
    vol_stat = $('input[name="board_design_entry[exceed_voltage]"]:checked').val()
    # Set to yes - check if desc entered 
    if vol_stat == '1'
      vol_desc = $("#board_design_entry_exceed_voltage_details").val()
      if !vol_desc # inform user desc required and prevent submit
        prevent_submit = 1
        $('#exceed_voltage_details_error').show()
    else # If unchecked set description to empty string
      $("#board_design_entry_exceed_voltage_details").val("")
  
    #### Check If Stacked Selected YES ####
    $('#stacked_resource_details_error').hide()
    stack_stat = $('input[name="board_design_entry[stacked_resource]"]:checked').val()
    # Set to yes - check if desc entered 
    if stack_stat == '1'
      stack_desc = $("#board_design_entry_stacked_resource_details").val()
      if !stack_desc # inform user desc required and prevent submit
        prevent_submit = 1
        $('#stacked_resource_details_error').show()
    else # If unchecked set description to empty string
      $("#board_design_entry_stacked_resource_details").val("")

    #### Check If Current Selected YES ####
    document.getElementById("exceed_current_details_error").style.display = 'none'
    cur_stat = $('input[name="board_design_entry[exceed_current]"]:checked').val()
    # Set to yes - check if desc entered 
    if cur_stat == '1'
      cur_desc = $("#board_design_entry_exceed_current_details").val()
      if !cur_desc # inform user desc required and prevent submit
        prevent_submit = 1
        $('#exceed_current_details_error').show()
    else # If unchecked set description to empty string
      $("#board_design_entry_exceed_current_details").val("")
    




    #### IF any check above prevents a submit then stop page submit
    if prevent_submit != 0
      alert "Please complete required fields."
      event.preventDefault()

