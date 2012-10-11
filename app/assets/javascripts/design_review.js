// On initial load of _reviewer_selections.html.erb only show incomplete reviews current user needs to perform
$(function() {
    $(".completeReview").hide();
    return false;
});


// Methods to show/hide reviews when user clicks a button
$(function() {
	var rows = $('table.reviewsTable tr');
	var incomplete = rows.filter('.incompleteReview');
	var complete = rows.filter('.completeReview');
	var numRows = rows.length;

	// Method for _reviewer_selections.html.erb	
	$("#showIncompleteReviews").click(function() {	
		incomplete.show();
	    complete.hide();
	    return false;
	});


	//Method for _reviewer_selections.html.erb
	$("#showCompletedReviews").click(function() {
		incomplete.hide();
	    complete.show();
	    return false;
	});


	//Method for _reviewer_selections.html.erb
	$("#showAllReviews").click(function() {
	    rows.show();
	    return false;
	});
});		
	