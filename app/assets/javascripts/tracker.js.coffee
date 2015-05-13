


jQuery ($) ->

  # manage display of review details
  $("#details> button").click ->
    if $(this).text() is "Show Details"
      $(this).text "Hide Details"
    else
      $(this).text "Show Details"
    $(this).next("#results_table").toggle()

  
  ############### DUAL MULTI SELECT LISTS ON MESSAGE BROADCAST PAGE ###############
  # Creates lists from grouped_collection_select
  # Also adds search at bottom using jquery.quicksearch.js
  $('#optgroup').multiSelect
    selectableOptgroup: true 
    selectableHeader: "<div class='custom-header'>Selectable Roles/Users</div>"
    selectableFooter: "<input type='text' class='search-input' autocomplete='off' placeholder='Search for Name'>",
    selectionHeader: "<div class='custom-header'>Selected Roles/Users</div>"
    selectionFooter: "<input type='text' class='search-input' autocomplete='off' placeholder='Search for Name'>",
    afterInit: (ms) ->
      that = this
      $selectableSearch = that.$selectableUl.next()
      $selectionSearch = that.$selectionUl.next()
      selectableSearchString = "#" + that.$container.attr("id") + " .ms-elem-selectable:not(.ms-selected)"
      selectionSearchString = "#" + that.$container.attr("id") + " .ms-elem-selection.ms-selected"
      that.qs1 = $selectableSearch.quicksearch(selectableSearchString)
      that.qs2 = $selectionSearch.quicksearch(selectionSearchString)
      return  
    afterSelect: ->
      @qs1.cache()
      @qs2.cache()
      return  
    afterDeselect: ->
      @qs1.cache()
      @qs2.cache()
      return
  
  # When mouse pointer hovers over role grouping name add class to it so css can highlight it
  $("li.ms-optgroup-label").mouseover (e) ->
    e.stopPropagation()
    $(this).addClass "opt-grp-hover"
    return
  
  # When mouse pointer leaves role grouping name remove class to it so css can stop highlighting it
  $("li.ms-optgroup-label").mouseout ->
    $(this).removeClass "opt-grp-hover"
    return
  
  # Action to add all roles/users to selected list  
  $("#select-all").click ->
    $("#optgroup").multiSelect "select_all"
    false
  
  # Action to remove all roles/users from selected list
  $("#deselect-all").click ->
    $("#optgroup").multiSelect "deselect_all"
    false

  # Toggles the display of exceptions which were not created by the current user. 
  # Also changes the text in the button that fires off this functionality
  $(".togglebutton").click (event) ->
    event.preventDefault()
    $("tr.notcuruser").toggle
      easing: "easeInOutCubic"
      duration: 500
    if $(".togglebutton").attr("value") is "Display All FIRs"
      $(".togglebutton").prop "value", "Display Only My FIRs"
    else
      $(".togglebutton").prop "value", "Display All FIRs"

  # On FIR Reviewer Dash open modal when "Create New Fab Issue" clicked
  $('.new_fir_button').click (event) ->
    event.preventDefault()
    button_id = $(this).attr("id")
    $("#edit_fir_design_"+button_id).modal()
    false





