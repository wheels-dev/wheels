component extends="wheels.WheelsTest" {

	function run() {

		describe("TenantResolver Middleware", function() {

			afterEach(function() {
				// Only clean up the tenant key, never wipe request.wheels
				if (IsDefined("request.wheels.tenant")) {
					StructDelete(request.wheels, "tenant");
				}
			});

			describe("Custom strategy", function() {

				it("sets request.wheels.tenant from resolver closure", function() {
					var fn = function(req) {
						return {id = "t1", dataSource = "tenant_one_ds", config = {showDebugInformation = false}};
					};
					var mw = new wheels.middleware.TenantResolver(resolver = fn);

					var reqData = {cgi = {server_name = "example.com"}};
					var result = {called = false, tenant = {}};

					var nextFn = function(r) {
						result.called = true;
						if (IsDefined("request.wheels.tenant")) {
							result.tenant = StructCopy(request.wheels.tenant);
						}
						return "";
					};
					mw.handle(request = reqData, next = nextFn);

					expect(result.called).toBeTrue();
					expect(result.tenant.id).toBe("t1");
					expect(result.tenant.dataSource).toBe("tenant_one_ds");
					expect(result.tenant["$locked"]).toBeTrue();
				});

				it("does not set tenant when resolver returns empty struct", function() {
					var fn = function(req) {
						return {};
					};
					var mw = new wheels.middleware.TenantResolver(resolver = fn);

					var reqData = {cgi = {}};
					var result = {hasTenant = false};

					var nextFn = function(r) {
						result.hasTenant = IsDefined("request.wheels.tenant");
						return "";
					};
					mw.handle(request = reqData, next = nextFn);

					expect(result.hasTenant).toBeFalse();
				});

				it("does not set tenant when resolver returns struct without dataSource", function() {
					var fn = function(req) {
						return {id = "t1"};
					};
					var mw = new wheels.middleware.TenantResolver(resolver = fn);

					var reqData = {cgi = {}};
					var result = {hasTenant = false};

					var nextFn = function(r) {
						result.hasTenant = IsDefined("request.wheels.tenant");
						return "";
					};
					mw.handle(request = reqData, next = nextFn);

					expect(result.hasTenant).toBeFalse();
				});

				it("provides default id and config when not returned by resolver", function() {
					var fn = function(req) {
						return {dataSource = "my_ds"};
					};
					var mw = new wheels.middleware.TenantResolver(resolver = fn);

					var reqData = {cgi = {}};
					var result = {tenant = {}};

					var nextFn = function(r) {
						if (IsDefined("request.wheels.tenant")) {
							result.tenant = StructCopy(request.wheels.tenant);
						}
						return "";
					};
					mw.handle(request = reqData, next = nextFn);

					expect(result.tenant.id).toBe("");
					expect(result.tenant.config).toBeStruct();
					expect(StructIsEmpty(result.tenant.config)).toBeTrue();
				});
			});

			describe("Header strategy", function() {

				it("passes request to resolver when header is present", function() {
					var fn = function(req) {
						return {id = "from_header", dataSource = "header_ds"};
					};
					var mw = new wheels.middleware.TenantResolver(
						strategy = "header",
						headerName = "X-Tenant-ID",
						resolver = fn
					);

					var reqData = {cgi = {http_x_tenant_id = "acme"}};
					var result = {tenant = {}};

					var nextFn = function(r) {
						if (IsDefined("request.wheels.tenant")) {
							result.tenant = StructCopy(request.wheels.tenant);
						}
						return "";
					};
					mw.handle(request = reqData, next = nextFn);

					expect(result.tenant.id).toBe("from_header");
					expect(result.tenant.dataSource).toBe("header_ds");
				});

				it("returns empty when header is missing", function() {
					var fn = function(req) {
						return {id = "t1", dataSource = "ds1"};
					};
					var mw = new wheels.middleware.TenantResolver(
						strategy = "header",
						headerName = "X-Tenant-ID",
						resolver = fn
					);

					var reqData = {cgi = {}};
					var result = {hasTenant = false};

					var nextFn = function(r) {
						result.hasTenant = IsDefined("request.wheels.tenant");
						return "";
					};
					mw.handle(request = reqData, next = nextFn);

					expect(result.hasTenant).toBeFalse();
				});
			});

			describe("Subdomain strategy", function() {

				it("passes request to resolver when subdomain exists", function() {
					var fn = function(req) {
						return {id = "acme", dataSource = "acme_ds"};
					};
					var mw = new wheels.middleware.TenantResolver(
						strategy = "subdomain",
						resolver = fn
					);

					var reqData = {cgi = {server_name = "acme.example.com"}};
					var result = {tenant = {}};

					var nextFn = function(r) {
						if (IsDefined("request.wheels.tenant")) {
							result.tenant = StructCopy(request.wheels.tenant);
						}
						return "";
					};
					mw.handle(request = reqData, next = nextFn);

					expect(result.tenant.id).toBe("acme");
				});

				it("returns empty when hostname has no subdomain", function() {
					var fn = function(req) {
						return {id = "t1", dataSource = "ds1"};
					};
					var mw = new wheels.middleware.TenantResolver(
						strategy = "subdomain",
						resolver = fn
					);

					var reqData = {cgi = {server_name = "example.com"}};
					var result = {hasTenant = false};

					var nextFn = function(r) {
						result.hasTenant = IsDefined("request.wheels.tenant");
						return "";
					};
					mw.handle(request = reqData, next = nextFn);

					expect(result.hasTenant).toBeFalse();
				});
			});

			describe("Cleanup", function() {

				it("cleans up request.wheels.tenant after next() completes", function() {
					var fn = function(req) {
						return {id = "t1", dataSource = "ds1"};
					};
					var mw = new wheels.middleware.TenantResolver(resolver = fn);

					var reqData = {cgi = {}};

					var nextFn = function(r) {
						return "";
					};
					mw.handle(request = reqData, next = nextFn);

					expect(IsDefined("request.wheels.tenant")).toBeFalse();
				});

				it("cleans up request.wheels.tenant even when next() throws", function() {
					var fn = function(req) {
						return {id = "t1", dataSource = "ds1"};
					};
					var mw = new wheels.middleware.TenantResolver(resolver = fn);

					var reqData = {cgi = {}};
					var result = {threw = false};

					var nextFn = function(r) {
						throw(type="TestException", message="boom");
					};

					try {
						mw.handle(request = reqData, next = nextFn);
					} catch (TestException e) {
						result.threw = true;
					}

					expect(result.threw).toBeTrue();
					expect(IsDefined("request.wheels.tenant")).toBeFalse();
				});
			});

		});
	}

}
