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
	    if (rows.length < 2) {
	    	header.hide();
	    }
	    else {
	    	header.show();
	    }
	    incomplete.show();
	    complete.show();
	    return false;
	});

	

	// METHODS FOR design_review/add_attachment

	// Method checks user chose a file and selected a document type when "Upload File" button is clicked
	// If above is not true then page is not submitted, empty fields are highlighted, and user is asked to fill out highlighted fields
	$("#uploadfile").click(function(event) {
		$(".document_type_row").removeClass(" highlight ");
		$(".file_select_row").removeClass(" highlight ");
		var doc_type_id = $("#document_type_id").val();
		var file_input = $("#document_document").val();
		if (!file_input) {
			$(".file_select_row").addClass(" highlight ");
		}
		if (!doc_type_id) {
			$(".document_type_row").addClass(" highlight ");
		}
		if (!file_input || !doc_type_id) {
			alert("Please fill in highlighted fields before trying to upload file.");		
			event.preventDefault();
		}
	});	


	//Method for approve_fab_houses.html.erb
	// Check if user is trying to submit page with no fab houses selected
	// and show alert message if design is in final and they have already signed off 
	$("#approveFabHousesButton").click(function() {
		$("#approve_fab_houses_warning").hide();
		var is_final_review = $("#approve_fab_houses_form").data('isfinalreview');
		var all_no_response = $("#approve_fab_houses_form").data('allnoresponse');

		//alert("fin " + is_final_review + "  res " + all_no_response);
		//event.preventDefault();

		var none_checked = true;
		// Get status of each checkbox
		$("input[type=checkbox]").each(function() {
		    var elem = $(this);
		    if (elem.is(":checked")) {
		    	none_checked = false;
		    }
		})
		
		// If none of the checkboxes are checked and this is final review and
		// user has review status other than No Response
		// then prevent page from submitting
		if (none_checked && !all_no_response && is_final_review) {
			event.preventDefault();
			$("#approve_fab_houses_warning").show();
			//alert("It appears you are trying to unapprove all Fab Houses during Final Review. You must first change your Review Status on all Roles for this Design Review to \"No Response\" before you can proceed.");
		}
	});

});












		
	
