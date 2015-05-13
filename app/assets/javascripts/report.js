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
	firchart.getAxisY2().getGrids().getMajor().setVisible(false);
	firchart.getAxisX().setStep(1);

	firchart.getData().setSeries(14);
	
	firchart.getSeries().getItem(0).setVisible(false);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(2).setGallery(cfx.Gallery.Bar);

	firchart.getSeries().getItem(3).setVisible(false);
	firchart.getSeries().getItem(4).setVisible(false);
	firchart.getSeries().getItem(5).setVisible(false);
	firchart.getSeries().getItem(6).setVisible(false);
	firchart.getSeries().getItem(7).setVisible(false);
	firchart.getSeries().getItem(8).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(8).setStacked(false);
	firchart.getSeries().getItem(9).setVisible(false);
	firchart.getSeries().getItem(10).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(10).setStacked(false);
	firchart.getSeries().getItem(11).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(11).setStacked(false);
	firchart.getSeries().getItem(12).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(12).setStacked(false);
	firchart.getSeries().getItem(12).setMarkerShape(cfx.MarkerShape.Triangle);
	firchart.getSeries().getItem(13).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(13).setStacked(false);
	firchart.getSeries().getItem(13).setMarkerShape(cfx.MarkerShape.Triangle);
	
	firchart.getSeries().getItem(8).setAxisY(firchart.getAxisY2());
	firchart.getSeries().getItem(10).setAxisY(firchart.getAxisY2());
	firchart.getSeries().getItem(11).setAxisY(firchart.getAxisY2());
	
	firchart.getAxisY().getTitle().setText("Issues/Pins");
	firchart.getAxisY().getLabelsFormat().setFormat(cfx.AxisFormat.Percentage);
	firchart.getAxisY2().getTitle().setText("Designs");

	firchart.setDataSource(jQuery.parseJSON(fir_quarts));
	chartDiv = document.getElementById('firQuartersChart');
	firchart.create(chartDiv);	
};



window.FirIssuesPinsChart = function(fir_deliv, firchart) {
	var chartDiv;
	//firchart.getDataGrid().setVisible(true);
	//firchart.getDataGrid().setShowHeader(false);
			
	firchart.getAxisY().getTitle().setText("Issues/Pins");
	firchart.getAxisX().setLabelAngle(45);
	firchart.getAxisY().getLabelsFormat().setDecimals(2);
	firchart.getAxisY().getLabelsFormat().setFormat(cfx.AxisFormat.Percentage);	 
	 
	firchart.getData().setSeries(4);
	firchart.getSeries().getItem(0).setVisible(false);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(2).setGallery(cfx.Gallery.Bar);
	
	firchart.setDataSource(jQuery.parseJSON(fir_deliv));
	chartDiv = document.getElementById('firIssuesPinsChart');
	firchart.create(chartDiv);
};


window.FirDeliverableChart = function(fir_deliv, firchart) {
	var chartDiv;
	firchart.getDataGrid().setVisible(true);
	firchart.getAxisY().getTitle().setText("Issues");

	firchart.getData().setSeries(4);
	firchart.getSeries().getItem(0).setVisible(false);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(2).setGallery(cfx.Gallery.Bar);
	
	firchart.setDataSource(jQuery.parseJSON(fir_deliv));
	chartDiv = document.getElementById('firDeliverableChart');
	firchart.create(chartDiv);
};

window.FirDrawingChart = function(fir_deliv, firchart) {
	var chartDiv;
	firchart.getDataGrid().setVisible(true);
	firchart.getAxisY().getTitle().setText("Issues");

	firchart.getData().setSeries(4);
	firchart.getSeries().getItem(0).setVisible(false);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(2).setGallery(cfx.Gallery.Bar);
	
	firchart.setDataSource(jQuery.parseJSON(fir_deliv));
	chartDiv = document.getElementById('firDrawingChart');
	firchart.create(chartDiv);
};

window.FirModeChart = function(fir_deliv, firchart) {
	var chartDiv;
	firchart.getDataGrid().setVisible(true);
	firchart.getAxisY().getTitle().setText("Issues");

	firchart.getData().setSeries(4);
	firchart.getSeries().getItem(0).setVisible(false);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(2).setGallery(cfx.Gallery.Bar);
	
	firchart.setDataSource(jQuery.parseJSON(fir_deliv));
	chartDiv = document.getElementById('firModeChart');
	firchart.create(chartDiv);
};




