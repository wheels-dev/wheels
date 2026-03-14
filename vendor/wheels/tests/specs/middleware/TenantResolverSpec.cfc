component extends="wheels.WheelsTest" {

	function run() {

		describe("TenantResolver Middleware", () => {

			afterEach(() => {
				if (StructKeyExists(request, "wheels")) {
					StructDelete(request.wheels, "tenant");
				}
			});

			describe("Custom strategy", () => {

				it("sets request.wheels.tenant from resolver closure", () => {
					var mw = new wheels.middleware.TenantResolver(
						resolver = function(req) {
							return {id: "t1", dataSource: "tenant_one_ds", config: {showDebugInformation: false}};
						}
					);

					var req = {cgi: {server_name: "example.com"}};
					var result = {called: false, tenant: {}};

					mw.handle(req, function(r) {
						result.called = true;
						if (StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant")) {
							result.tenant = Duplicate(r.wheels.tenant);
						}
						return "";
					});

					expect(result.called).toBeTrue();
					expect(result.tenant.id).toBe("t1");
					expect(result.tenant.dataSource).toBe("tenant_one_ds");
					expect(result.tenant["$locked"]).toBeTrue();
				});

				it("does not set tenant when resolver returns empty struct", () => {
					var mw = new wheels.middleware.TenantResolver(
						resolver = function(req) {
							return {};
						}
					);

					var req = {cgi: {}};
					var result = {hasTenant: false};

					mw.handle(req, function(r) {
						result.hasTenant = StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant");
						return "";
					});

					expect(result.hasTenant).toBeFalse();
				});

				it("does not set tenant when resolver returns struct without dataSource", () => {
					var mw = new wheels.middleware.TenantResolver(
						resolver = function(req) {
							return {id: "t1"};
						}
					);

					var req = {cgi: {}};
					var result = {hasTenant: false};

					mw.handle(req, function(r) {
						result.hasTenant = StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant");
						return "";
					});

					expect(result.hasTenant).toBeFalse();
				});

				it("provides default id and config when not returned by resolver", () => {
					var mw = new wheels.middleware.TenantResolver(
						resolver = function(req) {
							return {dataSource: "my_ds"};
						}
					);

					var req = {cgi: {}};
					var result = {tenant: {}};

					mw.handle(req, function(r) {
						if (StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant")) {
							result.tenant = Duplicate(r.wheels.tenant);
						}
						return "";
					});

					expect(result.tenant.id).toBe("");
					expect(result.tenant.config).toBeStruct();
					expect(StructIsEmpty(result.tenant.config)).toBeTrue();
				});
			});

			describe("Header strategy", () => {

				it("passes request to resolver when header is present", () => {
					var mw = new wheels.middleware.TenantResolver(
						strategy = "header",
						headerName = "X-Tenant-ID",
						resolver = function(req) {
							return {id: "from_header", dataSource: "header_ds"};
						}
					);

					var req = {cgi: {http_x_tenant_id: "acme"}};
					var result = {tenant: {}};

					mw.handle(req, function(r) {
						if (StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant")) {
							result.tenant = Duplicate(r.wheels.tenant);
						}
						return "";
					});

					expect(result.tenant.id).toBe("from_header");
					expect(result.tenant.dataSource).toBe("header_ds");
				});

				it("returns empty when header is missing", () => {
					var mw = new wheels.middleware.TenantResolver(
						strategy = "header",
						headerName = "X-Tenant-ID",
						resolver = function(req) {
							return {id: "t1", dataSource: "ds1"};
						}
					);

					var req = {cgi: {}};
					var result = {hasTenant: false};

					mw.handle(req, function(r) {
						result.hasTenant = StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant");
						return "";
					});

					expect(result.hasTenant).toBeFalse();
				});
			});

			describe("Subdomain strategy", () => {

				it("passes request to resolver when subdomain exists", () => {
					var mw = new wheels.middleware.TenantResolver(
						strategy = "subdomain",
						resolver = function(req) {
							return {id: "acme", dataSource: "acme_ds"};
						}
					);

					var req = {cgi: {server_name: "acme.example.com"}};
					var result = {tenant: {}};

					mw.handle(req, function(r) {
						if (StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant")) {
							result.tenant = Duplicate(r.wheels.tenant);
						}
						return "";
					});

					expect(result.tenant.id).toBe("acme");
				});

				it("returns empty when hostname has no subdomain", () => {
					var mw = new wheels.middleware.TenantResolver(
						strategy = "subdomain",
						resolver = function(req) {
							return {id: "t1", dataSource: "ds1"};
						}
					);

					var req = {cgi: {server_name: "example.com"}};
					var result = {hasTenant: false};

					mw.handle(req, function(r) {
						result.hasTenant = StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant");
						return "";
					});

					expect(result.hasTenant).toBeFalse();
				});
			});

			describe("Cleanup", () => {

				it("cleans up request.wheels.tenant after next() completes", () => {
					var mw = new wheels.middleware.TenantResolver(
						resolver = function(req) {
							return {id: "t1", dataSource: "ds1"};
						}
					);

					request.wheels = {};
					var req = request;

					mw.handle(req, function(r) {
						return "";
					});

					expect(StructKeyExists(request.wheels, "tenant")).toBeFalse();
				});

				it("cleans up request.wheels.tenant even when next() throws", () => {
					var mw = new wheels.middleware.TenantResolver(
						resolver = function(req) {
							return {id: "t1", dataSource: "ds1"};
						}
					);

					request.wheels = {};
					var req = request;
					var result = {threw: false};

					try {
						mw.handle(req, function(r) {
							throw(type="TestException", message="boom");
						});
					} catch (TestException e) {
						result.threw = true;
					}

					expect(result.threw).toBeTrue();
					expect(StructKeyExists(request.wheels, "tenant")).toBeFalse();
				});
			});

		});
	}

}
