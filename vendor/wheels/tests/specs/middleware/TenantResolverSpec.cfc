component extends="wheels.WheelsTest" {

	function run() {

		describe("TenantResolver Middleware", () => {

			afterEach(() => {
				StructDelete(request, "wheels");
			});

			describe("Custom strategy", () => {

				it("sets request.wheels.tenant from resolver closure", () => {
					var mw = new wheels.middleware.TenantResolver(
						resolver = function(req) {
							return {id: "t1", dataSource: "tenant_one_ds", config: {showDebugInformation: false}};
						}
					);

					var req = {cgi: {server_name: "example.com"}};
					var called = false;
					var capturedTenant = {};

					mw.handle(req, function(r) {
						called = true;
						if (StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant")) {
							capturedTenant = Duplicate(r.wheels.tenant);
						}
						return "";
					});

					expect(called).toBeTrue();
					expect(capturedTenant.id).toBe("t1");
					expect(capturedTenant.dataSource).toBe("tenant_one_ds");
					expect(capturedTenant["$locked"]).toBeTrue();
				});

				it("does not set tenant when resolver returns empty struct", () => {
					var mw = new wheels.middleware.TenantResolver(
						resolver = function(req) {
							return {};
						}
					);

					var req = {cgi: {}};
					var hasTenant = false;

					mw.handle(req, function(r) {
						hasTenant = StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant");
						return "";
					});

					expect(hasTenant).toBeFalse();
				});

				it("does not set tenant when resolver returns struct without dataSource", () => {
					var mw = new wheels.middleware.TenantResolver(
						resolver = function(req) {
							return {id: "t1"};
						}
					);

					var req = {cgi: {}};
					var hasTenant = false;

					mw.handle(req, function(r) {
						hasTenant = StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant");
						return "";
					});

					expect(hasTenant).toBeFalse();
				});

				it("provides default id and config when not returned by resolver", () => {
					var mw = new wheels.middleware.TenantResolver(
						resolver = function(req) {
							return {dataSource: "my_ds"};
						}
					);

					var req = {cgi: {}};
					var capturedTenant = {};

					mw.handle(req, function(r) {
						capturedTenant = Duplicate(r.wheels.tenant);
						return "";
					});

					expect(capturedTenant.id).toBe("");
					expect(capturedTenant.config).toBeStruct();
					expect(StructIsEmpty(capturedTenant.config)).toBeTrue();
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
					var capturedTenant = {};

					mw.handle(req, function(r) {
						if (StructKeyExists(r.wheels, "tenant")) {
							capturedTenant = Duplicate(r.wheels.tenant);
						}
						return "";
					});

					expect(capturedTenant.id).toBe("from_header");
					expect(capturedTenant.dataSource).toBe("header_ds");
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
					var hasTenant = false;

					mw.handle(req, function(r) {
						hasTenant = StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant");
						return "";
					});

					expect(hasTenant).toBeFalse();
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
					var capturedTenant = {};

					mw.handle(req, function(r) {
						if (StructKeyExists(r.wheels, "tenant")) {
							capturedTenant = Duplicate(r.wheels.tenant);
						}
						return "";
					});

					expect(capturedTenant.id).toBe("acme");
				});

				it("returns empty when hostname has no subdomain", () => {
					var mw = new wheels.middleware.TenantResolver(
						strategy = "subdomain",
						resolver = function(req) {
							return {id: "t1", dataSource: "ds1"};
						}
					);

					var req = {cgi: {server_name: "example.com"}};
					var hasTenant = false;

					mw.handle(req, function(r) {
						hasTenant = StructKeyExists(r, "wheels") && StructKeyExists(r.wheels, "tenant");
						return "";
					});

					expect(hasTenant).toBeFalse();
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
					var threw = false;

					try {
						mw.handle(req, function(r) {
							throw(type="TestException", message="boom");
						});
					} catch (TestException e) {
						threw = true;
					}

					expect(threw).toBeTrue();
					expect(StructKeyExists(request.wheels, "tenant")).toBeFalse();
				});
			});

		});
	}

}
