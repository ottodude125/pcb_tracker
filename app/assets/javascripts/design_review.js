// Methods to show/hide reviews when user clicks a button(All/Incomplete/Complete) in the reviewer_selections.html.erb section
$(function() {
	
	// variables for the _reviewer_selections.html.erb section of the page
   	var rows = $('table.reviewsTable tr'); // get all the rows in the table
	var header = rows.filter('.th1'); // header row
	var incomplete = rows.filter('.incompleteReview'); // incomplete reviews
	var complete = rows.filter('.completeReview'); // complete reviews

	//On initial load of _reviewer_selections.html.erb only show incomplete reviews current user needs to perform
    $(".completeReview").hide();

    // On initial load of _reviewer_selections.html.erb only show header for reviews section if the user has some incompleted reviews
	if (incomplete.length < 1) {
		header.hide();
	}
    
	// Method for _reviewer_selections.html.erb	
	$("#showIncompleteReviews").click(function() {
		if (incomplete.length > 0) {
			header.show();
			incomplete.show();
		}
		else {
			header.hide();
		}
		complete.hide();
	    return false;
	});


	//Method for _reviewer_selections.html.erb
	$("#showCompletedReviews").click(function() {
		if (complete.length > 0) {
			header.show();
			complete.show();
		}
		else {
			header.hide();
		}
		incomplete.hide();
	    return false;
	});


	//Method for _reviewer_selections.html.erb
	$("#showAllReviews").click(function() {
	    if (rows.length > 0) {
	    	header.hide();
	    }
	    rows.show();
	    return false;
	});
});		
	