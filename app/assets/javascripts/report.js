$(function ()  {
	$( "#from" ).datepicker({
		setDate: $(this).attr("value"),
		minDate: $(this).attr("min"),
		maxDate: $(this).attr("max"),
		changeMonth: true,
		numberOfMonths: 1,
		showOn: "button",
		buttonImage: "/pcbtr/assets/calendar.gif",
		buttonImageOnly: true,
		changeMonth: true,
		changeYear: true,
		onClose: function( selectedDate ) {
			$( "#to" ).datepicker( "option", "minDate", selectedDate );
		}
	});

	$( "#to" ).datepicker({
		setDate: $(this).attr("value"),
		minDate: $(this).attr("min"),
		maxDate: $(this).attr("max"),
		changeMonth: true,
		numberOfMonths: 1,
		showOn: "button",
		buttonImage: "/pcbtr/assets/calendar.gif",
		buttonImageOnly: true,
		changeMonth: true,
		changeYear: true,
		onClose: function( selectedDate ) {
			$( "#from" ).datepicker( "option", "maxDate", selectedDate );
		}
	});
});
