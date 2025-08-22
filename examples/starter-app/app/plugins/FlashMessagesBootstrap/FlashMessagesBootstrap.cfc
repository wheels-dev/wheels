component {

	public any function init() {
		this.version = "2.0.0,2.2.0";
		return this;
	}

	public string function flashMessages(){
		// call the core flashMessages function to get the prebuilt markup block
		local.result = core.flashMessages(argumentCollection=arguments);

		// if block is not empty lets Bootstrapify it
		if (local.result neq "") {
			// remove the bounding DIV tags
		local.result = replace(local.result, '<div class="flash-messages">', '');
		local.result = replace(local.result, '</div>', '');

		// change the bounding P tags to DIV tags
		local.result = replace(local.result, '<p', '<div', 'all');
		local.result = replace(local.result, '</p>', '</div>', 'all');

		// build the string to append for the button and close event
		var local.append = ' role="alert"><button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close"><span aria-hidden="true"></span></button>';

		// handle the four standard Bootstrap alert types
		local.result = replace(local.result, 'class="success-message">', 'class="alert alert-success alert-dismissible"' & local.append, 'all');
		local.result = replace(local.result, 'class="info-message">', 'class="alert alert-info alert-dismissible"' & local.append, 'all');
		local.result = replace(local.result, 'class="warning-message">', 'class="alert alert-warning alert-dismissible"' & local.append, 'all');
		local.result = replace(local.result, 'class="danger-message">', 'class="alert alert-danger alert-dismissible"' & local.append, 'all');

		// convert an error key in the flash structure to a standard Bootstrap danger alert
		local.result = replaceNoCase(result, 'class="error-message">', 'class="alert alert-danger alert-dismissible"' & local.append, 'all');

		// convert any other key in the flash structure to a standard Bootstrap info alert
		local.result = reReplace(result, 'class=".*?-message">', 'class="alert alert-info alert-dismissible"' & local.append, 'all');
		}
		return local.result;
	}
}
