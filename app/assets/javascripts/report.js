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

window.FirQuartersChart = function(fir_quarts, firchart) {
	var chartDiv;
	firchart.getData().setSeries(5);
	firchart.getAxisY().getTitle().setText("Hours");
	firchart.getSeries().getItem(0).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	//firchart.getAllSeries().setStackedStyle(cfx.Stacked.Normal);
	firchart.getAxisY().getGrids().getMajor().setVisible(false);
	firchart.getAxisY().getLabelsFormat().setDecimals(2);
	firchart.getAxisY2().getGrids().getMajor().setVisible(false);

	firchart.getSeries().getItem(2).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(2).setStacked(false);
	firchart.getSeries().getItem(3).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(3).setStacked(false);
	firchart.getSeries().getItem(4).setGallery(cfx.Gallery.Lines);
	firchart.getSeries().getItem(4).setStacked(false);
	
	firchart.getSeries().getItem(2).setAxisY(firchart.getAxisY2());
	firchart.getSeries().getItem(3).setAxisY(firchart.getAxisY2());
	firchart.getSeries().getItem(4).setAxisY(firchart.getAxisY2());
	
	firchart.getAxisY().getTitle().setText("Issues/Boards");
	firchart.getAxisY2().getTitle().setText("Designs");
	
	firchart.setDataSource(jQuery.parseJSON(fir_quarts));
	chartDiv = document.getElementById('firQuartersChart');
	firchart.create(chartDiv);
};

window.FirIssuesPinsChart = function(fir_deliv, firchart) {
	var chartDiv;
	firchart.getData().setSeries(3);
	firchart.getSeries().getItem(0).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	
	firchart.setDataSource(jQuery.parseJSON(fir_deliv));
	chartDiv = document.getElementById('firIssuesPinsChart');
	firchart.create(chartDiv);
};

window.FirDeliverableChart = function(fir_deliv, firchart) {
	var chartDiv;
	firchart.getData().setSeries(3);
	firchart.getSeries().getItem(0).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	
	firchart.setDataSource(jQuery.parseJSON(fir_deliv));
	chartDiv = document.getElementById('firDeliverableChart');
	firchart.create(chartDiv);
};

window.FirDrawingChart = function(fir_deliv, firchart) {
	var chartDiv;
	firchart.getData().setSeries(3);
	firchart.getSeries().getItem(0).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	
	firchart.setDataSource(jQuery.parseJSON(fir_deliv));
	chartDiv = document.getElementById('firDrawingChart');
	firchart.create(chartDiv);
};

window.FirModeChart = function(fir_deliv, firchart) {
	var chartDiv;
	firchart.getData().setSeries(3);
	firchart.getSeries().getItem(0).setGallery(cfx.Gallery.Bar);
	firchart.getSeries().getItem(1).setGallery(cfx.Gallery.Bar);
	
	firchart.setDataSource(jQuery.parseJSON(fir_deliv));
	chartDiv = document.getElementById('firModeChart');
	firchart.create(chartDiv);
};






