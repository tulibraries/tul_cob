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
//= require jquery_ujs
//= require turbolinks//
// Required by Blacklight
//= require blacklight/blacklight

//= require blacklight_alma/blacklight_alma

//= require_tree .
function selectall() {
	var x = document.getElementsByName("renewselected");
	var i;
	for (i = 0; i < x.length; i++) {
	    if (x[i].type == "checkbox") {
	        x[i].checked = true;
	    }
	}
	document.getElementById("selectall").style.display = "none";
	document.getElementById("deselectall").style.display = "block";
}
function deselectall() {
	var x = document.getElementsByName("renewselected");
	var i;
	for (i = 0; i < x.length; i++) {
	    if (x[i].type == "checkbox") {
	        x[i].checked = false;
	    }
	}
	document.getElementById("selectall").style.display = "block";
	document.getElementById("deselectall").style.display = "none";
}