# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/



window.toggleVis = (target, visible) ->
  
  # toggles the visibility of target
  # IMPORTANT: this method will only work with divs hidden with '.hidden'
  #uses: toggleVis('#id')
  #      toggleVis('.class')
  #      toggleVis('.class1, .class2, class3...')
  #      toggleVis('.class, #id')
  #      toggleVis(target, true) sets target visible
  #      toggleVis(target, false) sets target hidden
  #alert("target " + target + " visible " + visible);
  $(target).each ->
    unless visible is `undefined`
      if visible
        $(this).removeClass "hidden"
      else
        $(this).addClass "hidden"
    else if $(this).attr("class") is `undefined` or $(this).attr("class").indexOf("hidden") is -1
      $(this).addClass "hidden"
    else
      $(this).removeClass "hidden"






jQuery ->
  $('#fab_quarterly_statuses_table').dataTable
    sPaginationType: "full_numbers",
    bJQueryUI: true,
    "iDisplayLength": 25,
    aaSorting: [[1,'desc'],[0,'desc']]


  $(".style_help_button").unbind "click"

  $(".style_help_button").on "click", (e) ->
    e.preventDefault()
    toggleVis $(this).parent().find(".style_help")
