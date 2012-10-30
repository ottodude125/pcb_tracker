# manage display of review details
jQuery ($) ->
  $("#details> button").click ->
    if $(this).text() is "Show Details"
      $(this).text "Hide Details"
    else
      $(this).text "Show Details"
    $(this).next("#results_table").toggle()

