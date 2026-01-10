$(document).ready(function($) {

	// Logging modals
	$('#logModalCenter').on('show.bs.modal', function (e) {
	  var link = $(e.relatedTarget);
	  var modal = $(this);
	  $.get( link.data('remoteurl'), function(r){
	  	var highlighted = syntaxHighlight( JSON.stringify(r, undefined, 4) );
	  		modal.find('.modal-body').html(
	  		  "<pre>" + highlighted + "</pre>"
	  		);
	  });
	});

	// Logging highlighting
	function syntaxHighlight(json) {
	    json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
	    return json.replace(/("(\\u[a-zA-Z0-9]{4}|\\[^u]|[^\\"])*"(\s*:)?|\b(true|false|null)\b|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?)/g, function (match) {
	        var cls = 'number';
	        if (/^"/.test(match)) {
	            if (/:$/.test(match)) {
	                cls = 'key';
	            } else {
	                cls = 'string';
	            }
	        } else if (/true|false/.test(match)) {
	            cls = 'boolean';
	        } else if (/null/.test(match)) {
	            cls = 'null';
	        }
	        return '<span class="' + cls + '">' + match + '</span>';
	    });
	}

});
