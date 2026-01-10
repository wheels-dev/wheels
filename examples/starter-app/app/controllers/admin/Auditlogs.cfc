component extends="app.controllers.Controller" {

	function config() {
		super.config(restrictAccess=true);
		verifies(except="index,show", params="key", paramsTypes="integer", handler="objectNotFound");
		filters(through="getFilterTypes", only="index");
		filters(through="isAjaxRequest", only="show");
		provides("html,json");
		//usesLayout(template=false, only="show");
	}

	/**
	* View all logs
	**/
	function index() {
		try{
			param name="params.q" default="";
			param name="params.type" default="";
			param name="params.severity" default="";
			param name="params.page" default=1;
			param name="params.perpage" default=100;
			param name="params.from" default=dateFormat(dateAdd('d', -30, now()), 'yyyy-mm-dd');
			param name="params.to" default=dateFormat(now(), 'yyyy-mm-dd');

			local.where=[];

			// Whilst our date range picker is passing through a year/month/day,
			// we want to be more explicit in what date range we actually want to search
			local.from 	= CreateDateTime(year(params.from), month(params.from), day(params.from), 0, 0, 0);
			local.to 	= CreateDateTime(year(params.to), month(params.to), day(params.to), 23, 59, 59);

			arrayAppend(local.where, "createdAt >= '#local.from#'");
			arrayAppend(local.where, "createdAt < '#local.to#'");

			if(len(params.type)){
				arrayAppend(local.where, "type = '#params.type#'");
			}
			if(len(params.severity)){
				arrayAppend(local.where, "severity = '#params.severity#'");
			}
			if(len(params.q)){
				local.qWhere=[];
				var sanitizedQ=stripTags(params.q);

				if(len(params.q) GT 50){
					params.q = "";
				} else {
					arrayAppend(local.qWhere, "message LIKE '%#params.q#%'");
					arrayAppend(local.where, whereify(local.qWhere, "OR"));
				}
			}
			auditlogs=model("auditlog").getAuditLog(local.where, params.perpage, params.page);
		} catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}
	}

	/**
	* Show Log Detail via AJAX JSON
	**/
	function show() {
		try{
			log = model("auditlog").getAuditLogByKey(params.key);
			renderWith(data=deserializeJSON(log.data));
		} catch (any e) {
			redirectTo(action="index", error="Error: #e.message#");
		}	
	}

	/**
	* Get Filter Data
	**/
	private function getFilterTypes(){
		logtypes = model("auditlog").getAuditLogBySelect("DISTINCT type AS logtype");
		severitytypes = model("auditlog").getAuditLogBySelect("DISTINCT severity AS severitytype");
	}
	/**
	* Redirect away if verifies fails, or if an object can't be found
	**/
	private function objectNotFound() {
		redirectTo(action="index", error="That permission wasn't found");
	}

}
