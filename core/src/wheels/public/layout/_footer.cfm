<!--- cfformat-ignore-start --->
</div></div><!--/main-->
<cfif request.isFluid>
</div>
</cfif>
<script>
//=====================================================================
//= 	Javascript for CFWheels GUI
//=====================================================================
	$(document).ready(function() {
//=====================================================================
//= 	Routes / Package table filter
//=====================================================================

	// Write on keyup event of keyword input element
	$(".table-searcher").keyup(function() {
		// When value of the input is not blank
		if( $(this).val() != "") {
			// Show only matching TR, hide rest of them
			$(".searchable tbody>tr").hide();
			$(".searchable td:contains-ci('" + $(this).val() + "')").parent("tr").show();
			var c = $('.searchable tbody>tr:visible').length;
			$(".matched-count > .icon").hide();
			$(".matched-count-value").html(c + ' matches');
		} else {
			// When there is no input or clean again, show everything back
			$(".matched-count-value").html("");
			$(".matched-count > .icon").show();
			$(".searchable tbody>tr").show();
		}
	});

	// Route Tester
	$(".route-test").on("click", function(e){
		e.preventDefault();

		$("#router-tester-results").html('<div class="ui segment"><div class="ui active inverted dimmer"><div class="ui text large loader">Loading</div></div><p></p> <p></p><p></p></div>');

		var data = {
			'verb': $("#route-tester-verb").val(),
			'path': $("#route-tester-path").val()
		}

		var testUrl = $(this).data("test-url");

		if( data.path[0] != '/')
			data.path = '/' + data.path;

			var resp = $.ajax({
				url: testUrl,
				method: 'post',
				data: data
			})
			.done(function(data, status, req) {
			var res = $("#router-tester-results");
			res.html(data);
			})
			.fail(function(e) {
			//alert( "error" );
			})
			.always(function(r) {
			//console.log(r);
			});

	});

//=====================================================================
//= 	Docs
//=====================================================================


	checkForUrlHash();
	updateFunctionCount();
	hljs.initHighlightingOnLoad();

	$(window).on('hashchange',function(){
		filterByFunctionName(location.hash.slice(1));
	});

	// L: #function-navigation
	// Center: #function-output
	// R #function-category-list


	$("#function-category-list .section, #function-output .section").on("click", function(e){
		filterBySection($(this).data("section"));
		updateFunctionCount();
		e.preventDefault();
	});
	$("#function-category-list .category, #function-output .category").on("click", function(e){
		filterByCategory($(this).data("section"), $(this).data("category"));
		updateFunctionCount();
		e.preventDefault();
	});

	$(".docreset").on("click", function(e){
		resetSearch();
		e.preventDefault();
	});

	$("#function-navigation .functionlink,  #function-output .functionlink").on("click", function(e){
		filterByFunctionName($(this).data("function"));
		$(".functionlink").removeClass("active");
		$(this).addClass("active");
		updateFunctionCount();
		e.preventDefault();
	});

	$("#function-output .filtersection").on("click", function(e){
		filterBySection($(this).closest(".functiondefinition").data("section"));
		updateFunctionCount();
		e.preventDefault();
	});

	$("#function-output .filtercategory").on("click", function(e){
		var parent=$(this).closest(".functiondefinition");
		filterByCategory(parent.data("section"),parent.data("category"));
		updateFunctionCount();
		e.preventDefault();
	});
	function resetSearch(){
		$(".functiondefinition").show();
		$(".functionlink").show();
		updateFunctionCount();
	}
	function filterByFunctionName(name){
		$("#function-output").find(".functiondefinition").hide().end()
			.find("[data-function='" + name + "']").show().end()
			.find("#" + name).show();
		window.location.hash="#" + name;
	}
	function filterByCategory(section, category){
		$("#function-navigation").find(".functionlink").hide().end()
			.find('[data-section="' + section + '"][data-category="' + category + '"]').show();
		$("#function-output").find(".functiondefinition").hide().end()
			.find('[data-section="' + section + '"][data-category="' + category + '"]').show();
	}
	function filterBySection(section){
		$("#function-navigation").find(".functionlink").hide().end()
			.find('[data-section="' + section + '"]').show();
		$("#function-output").find(".functiondefinition").hide().end()
			.find('[data-section="' + section + '"]').show();
	}
	function updateFunctionCount(){
		$("#functionResults .resultCount").html($("#function-output .functiondefinition:visible").length);
	}

	function checkForUrlHash(){
		var match = location.hash.match(/^#?(.*)$/)[1];
		if (match){filterByFunctionName(match);}
	}

  // Write on keyup event of keyword input element
  $("#doc-search").keyup(function(){
    // When value of the input is not blank
    if( $(this).val() != "")
    {
      $("#function-output").find(".functiondefinition").hide().end();
      $("#function-navigation").find(".functionlink").hide().end();
      $("#function-output .functiondefinition .functitle:contains-ci('" + $(this).val() + "')").parent().show();
      $("#function-navigation .functionlink:contains-ci('" + $(this).val() + "')").show();
		updateFunctionCount();
    }
    else
    {
	  resetSearch();
      // When there is no input or clean again, show everything back
      $("#function-output a").show();
      updateFunctionCount();
    }
  });

//=====================================================================
//= 	Utils
//=====================================================================
// jQuery expression for case-insensitive filter
$.extend($.expr[":"], {
	"contains-ci": function(elem, i, match, array) {
		return (elem.textContent || elem.innerText || $(elem).text() || "").toLowerCase().indexOf((match[3] || "").toLowerCase()) >= 0;
	}
});
//=====================================================================
//= 	Semantic UI
//=====================================================================
// Activate Menus
$('.menu .item').tab();
$('.ui.dropdown')
  .dropdown();
});
$('.ui.sticky')
  .sticky({
    offset       : 50,
    bottomOffset : 50,
    context: '#top'
  })
;
$('.ui.radio.checkbox')
  .checkbox()
;

</script>

</body>
</html>
<!--- cfformat-ignore-end --->
