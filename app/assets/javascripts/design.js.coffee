


jQuery ($) ->

  # Toggles the display of designs which were not created by the current user. 
  # Also changes the text in the button that fires off this functionality
  $(".toggle_design_list").click (event) ->
    event.preventDefault()
    $("tr.not_involved").toggle
      easing: "easeInOutCubic"
      duration: 500
    if $(".toggle_design_list").attr("value") is "Display All Active Designs"
      $(".toggle_design_list").prop "value", "Display My Active Designs"
      $('h1').text 'All Active Designs'
    else
      $(".toggle_design_list").prop "value", "Display All Active Designs"
      $('h1').text 'My Active Designs'


