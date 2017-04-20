// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require 'blacklight_advanced_search'


//= require jquery_ujs
//= require turbolinks//
// Required by Blacklight
//= require blacklight/blacklight

//= require blacklight_alma/blacklight_alma

// For blacklight_range_limit built-in JS, if you don't want it you don't need
// this:
//= require 'blacklight_range_limit'

//= require_tree .

// For blacklight_range_limit built-in JS, if you don't want it you don't need
// this:
//= require 'blacklight_range_limit'

$(document).ready(function(){
	$(this).find(':input[id=renew_selected]').prop('disabled', true);
	$('input[type=checkbox]').click(function(){
		var x = document.getElementsByName("loan_ids[]");
		var y = document.getElementById("checkall");
		var checked = false;
		var i;
		$(x).each(function() {
			if( $(this).prop('checked')){
		      checked = true;
		    }
		});
		if (checked == true) {
	    	$(document).find(':input[id=renew_selected]').prop('disabled', false);
	    }
	    else $(document).find(':input[id=renew_selected]').prop('disabled', true);
	});
});


function selectallchecks() {
	var x = document.getElementsByName("loan_ids[]");
	var y = document.getElementById("checkall");
	var i;
	if (y.checked == true) {
		for (i = 0; i < x.length; i++) {
		    if (x[i].type == "checkbox") {
		        x[i].checked = true;
		    }
		}
	}
	else {
		for (i = 0; i < x.length; i++) {
		    if (x[i].type == "checkbox") {
		        x[i].checked = false;
		    }
		}
	}
}

function deselectallchecks() {
	var x = document.getElementsByName("loan_ids[]");
	var y = document.getElementById("checkall");
	y.checked = false;
	var i;
	for (i = 0; i < x.length; i++) {
	    if (x[i].type == "checkbox") {
	        x[i].checked = false;
	    }
	}
}

