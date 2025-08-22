
<cfparam name="logtypes">
<cfparam name="severitytypes">
<cfoutput>
#startFormTag(route="logs", method="get", class="form-inline mb-2")#
	<div class="row">
	    <div class="col-12 col-sm-4 col-md-2">
	 		#selectTag(name="severity", options=severitytypes, includeBlank="All Levels", selected=params.severity, label="Severity", prependToLabel="<div class=""form-group mb-2"">", labelClass="sr-only")#
		</div>
	    <div class="col-12 col-sm-4 col-md-2">
	 		#selectTag(name="type", options=logtypes, includeBlank="All Types", selected=params.type, label="Type", prependToLabel="<div class=""form-group mb-2"">", labelClass="sr-only")#
		</div>

		<div class="col-12 col-sm-4 col-md-3">
			#textFieldTag(name="q", value=params.q, label="Keyword Search", labelClass="sr-only", placeholder="Keyword")#
		</div>

		<div id="reportrange" class="col-12 col-sm-8 col-md-4">
		    <i class="fa fa-calendar"></i>&nbsp;
		    <span></span> <i class="fa fa-caret-down"></i>
		</div>
		#hiddenFieldTag(name="from", value=params.from)#
		#hiddenFieldTag(name="to", value=params.to)#

	    <div class="col-12 col-sm-4 col-md-1">
			#submitTag(value="Filter", class="btn btn-info text-white")#
		</div>
	</div>
#endFormTag()#
</cfoutput>

<cfsavecontent variable="request.js.reportrange">
<script>
$(function() {

    var start = moment( $("#from").val() );
    var end = moment( $("#to").val() );

    function cb(start, end) {
    	$("#from").val(start.format('YYYY-MM-DD'));
    	$("#to").val(end.format('YYYY-MM-DD'));
        $('#reportrange span').html(start.format('MMMM D, YYYY') + ' - ' + end.format('MMMM D, YYYY'));
    }

    $('#reportrange').daterangepicker({
        startDate: start,
        endDate: end,
        ranges: {
           'Today': [moment(), moment()],
           'Yesterday': [moment().subtract(1, 'days'), moment().subtract(1, 'days')],
           'Last 7 Days': [moment().subtract(6, 'days'), moment()],
           'Last 30 Days': [moment().subtract(29, 'days'), moment()],
           'This Month': [moment().startOf('month'), moment().endOf('month')],
           'Last Month': [moment().subtract(1, 'month').startOf('month'), moment().subtract(1, 'month').endOf('month')]
        }
    }, cb);

    cb(start, end);

});
</script>
</cfsavecontent>
