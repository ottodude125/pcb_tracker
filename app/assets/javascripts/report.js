// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.
// You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
//= require ./jchartfx745596/jchartfx.system.js
//= require ./jchartfx745596/jchartfx.coreVector.js

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

	$('#fir_board_data_table').dataTable({
	    sPaginationType: "full_numbers",
	    bJQueryUI: true,
	    "iDisplayLength": 30,
	    aaSorting: [[0,'desc']]		
	});
	$('#fir_doc_issues_table').dataTable({
	    sPaginationType: "full_numbers",
	    bJQueryUI: true,
	    "iDisplayLength": 30,
	    aaSorting: [[0,'desc']]		
	});
	$('#fir_clar_issues_table').dataTable({
	    sPaginationType: "full_numbers",
	    bJQueryUI: true,
	    "iDisplayLength": 30,
	    aaSorting: [[0,'desc']]		
	});

	$("#fir_metrics_tabs").tabs({
		event: "click"
	});
});

// JchartFX does not allow you to select the color to use for the series
// Therefore there are 7 extra series added so that each bar/line is a specific color
window.FirQuartersChart = function(fir_quarts, firchart) {
	var chartDiv;
	firchart.getDataGrid().setVisible(true);
	firchart.getDataGrid().setBackColorData("#00FF00");
	firchart.getDataGrid().setBackColorDataAlternate("#FF0000");
	firchart.getDataGrid().setInterlaced(cfx.Interlaced.Horizontal);

	firchart.getAxisY().getGrids().getMajor().setVisible(false);
	firchart.getAxisY().getLabelsFormat().setDecimals(2);
	firchart.getAxisY().getTitle().setText("Issues/Pins");
	firchart.getAxisY().getLabelsFormat().setFormat(cfx.AxisFormat.Percentage);
	firchart.getAxisY2().getGrids().getMajor().setVisible(false);
	firchart.getAxisY2().getTitle().setText("Designs");
	firchart.getAxisX().setStep(1);	

	firchart.getData().setSeries(8);

	firchart.getSeries().getItem(2).setAxisY(firchart.getAxisY2());
	firchart.getSeries().getItem(3).setAxisY(firchart.getAxisY2());
	firchart.getSeries().getItem(4).setAxisY(firchart.getAxisY2());

	firchart.getSeries().getItem(0).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	
	firchart.getSeries().getItem(2).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(2).setStacked(false);
	firchart.getSeries().getItem(3).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(3).setStacked(false);
	firchart.getSeries().getItem(4).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(4).setStacked(false);	
	
	firchart.getSeries().getItem(5).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(5).setStacked(false);
	firchart.getSeries().getItem(5).setMarkerShape(cfx.MarkerShape.Triangle);	
	
	firchart.getSeries().getItem(6).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(6).setStacked(false);
	firchart.getSeries().getItem(6).setMarkerShape(cfx.MarkerShape.Triangle);
	
	firchart.getSeries().getItem(0).setColor("#D3696C");
	firchart.getSeries().getItem(1).setColor("#55AA55");
	firchart.getSeries().getItem(2).setColor("#000000");
	firchart.getSeries().getItem(3).setColor("#7E1518");
	firchart.getSeries().getItem(4).setColor("#116611");
	firchart.getSeries().getItem(5).setColor("#A8383B");
	firchart.getSeries().getItem(6).setColor("#2D882D");
	
	firchart.setDataSource(fir_quarts);
	chartDiv = document.getElementById('firQuartersChart');
	firchart.create(chartDiv);
	
};



window.FirIssuesPinsChart = function(fir_deliv, firchart) {
	var chartDiv;
			
	firchart.getAxisY().getTitle().setText("Issues/Pins");
	firchart.getAxisX().setLabelAngle(45);
	firchart.getAxisY().getLabelsFormat().setDecimals(2);
	firchart.getAxisY().getLabelsFormat().setFormat(cfx.AxisFormat.Percentage);	 
	 
	firchart.getData().setSeries(3);
	firchart.getSeries().getItem(0).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);

	firchart.getSeries().getItem(0).setColor("#D3696C");
	firchart.getSeries().getItem(1).setColor("#55AA55");

	firchart.setDataSource(jQuery.parseJSON(fir_deliv));
	chartDiv = document.getElementById('firIssuesPinsChart');
	firchart.create(chartDiv);
};


window.FirDeliverableChart = function(fir_deliv, firchart) {
	var chartDiv;
	firchart.getDataGrid().setVisible(true);
	firchart.getAxisY().getTitle().setText("Issues");

	firchart.getData().setSeries(3);
	firchart.getSeries().getItem(0).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	
	firchart.getSeries().getItem(0).setColor("#D3696C");
	firchart.getSeries().getItem(1).setColor("#55AA55");

	firchart.setDataSource(jQuery.parseJSON(fir_deliv));
	chartDiv = document.getElementById('firDeliverableChart');
	firchart.create(chartDiv);
};

window.FirDrawingChart = function(fir_deliv, firchart) {
	var chartDiv;
	firchart.getDataGrid().setVisible(true);
	firchart.getAxisY().getTitle().setText("Issues");

	firchart.getData().setSeries(3);
	firchart.getSeries().getItem(0).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	
	firchart.getSeries().getItem(0).setColor("#D3696C");
	firchart.getSeries().getItem(1).setColor("#55AA55");

	firchart.setDataSource(jQuery.parseJSON(fir_deliv));
	chartDiv = document.getElementById('firDrawingChart');
	firchart.create(chartDiv);
};

window.FirModeChart = function(fir_deliv, firchart) {
	var chartDiv;
	firchart.getDataGrid().setVisible(true);
	firchart.getAxisY().getTitle().setText("Issues");

	firchart.getData().setSeries(2);
	firchart.getSeries().getItem(0).setGallery(cfx.Gallery.Bar);
	
	firchart.getSeries().getItem(0).setColor("#D3696C");

	firchart.setDataSource(jQuery.parseJSON(fir_deliv));
	chartDiv = document.getElementById('firModeChart');
	firchart.create(chartDiv);
};




