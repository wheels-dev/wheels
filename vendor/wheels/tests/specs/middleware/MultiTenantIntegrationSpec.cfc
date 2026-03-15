/**
 * Integration test: verifies multi-tenant datasource switching with real databases.
 *
 * Requires two H2 datasources:
 *   - wheelstestdb_h2          (default / "tenant A")
 *   - wheelstestdb_h2_tenant_b ("tenant B")
 *
 * Both are configured in tools/docker/lucee7/CFConfig.json.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Multi-Tenant Integration (real databases)", function() {

			var dsA = "wheelstestdb_h2";
			var dsB = "wheelstestdb_h2_tenant_b";

			beforeEach(function() {
				// Ensure clean tenant state
				if (IsDefined("request.wheels.tenant")) {
					StructDelete(request.wheels, "tenant");
				}

				// Create and seed tables fresh for every test
				try { QueryExecute("DROP TABLE IF EXISTS mt_products", [], {datasource = dsA}); } catch (any e) {}
				try { QueryExecute("DROP TABLE IF EXISTS mt_products", [], {datasource = dsB}); } catch (any e) {}

				QueryExecute("
					CREATE TABLE mt_products (
						id INT AUTO_INCREMENT PRIMARY KEY,
						name VARCHAR(100) NOT NULL,
						price DECIMAL(10,2) NOT NULL DEFAULT 0,
						createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
						updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
					)
				", [], {datasource = dsA});

				QueryExecute("
					CREATE TABLE mt_products (
						id INT AUTO_INCREMENT PRIMARY KEY,
						name VARCHAR(100) NOT NULL,
						price DECIMAL(10,2) NOT NULL DEFAULT 0,
						createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
						updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
					)
				", [], {datasource = dsB});

				QueryExecute("INSERT INTO mt_products (name, price) VALUES ('Widget-A', 10.00)", [], {datasource = dsA});
				QueryExecute("INSERT INTO mt_products (name, price) VALUES ('Widget-A2', 15.00)", [], {datasource = dsA});
				QueryExecute("INSERT INTO mt_products (name, price) VALUES ('Gadget-B', 20.00)", [], {datasource = dsB});
			});

			afterEach(function() {
				if (IsDefined("request.wheels.tenant")) {
					StructDelete(request.wheels, "tenant");
				}
				try { QueryExecute("DROP TABLE IF EXISTS mt_products", [], {datasource = dsA}); } catch (any e) {}
				try { QueryExecute("DROP TABLE IF EXISTS mt_products", [], {datasource = dsB}); } catch (any e) {}
			});

			it("sets up isolated tables in each datasource", function() {
				var countA = QueryExecute("SELECT COUNT(*) AS cnt FROM mt_products", [], {datasource = dsA});
				var countB = QueryExecute("SELECT COUNT(*) AS cnt FROM mt_products", [], {datasource = dsB});

				expect(countA.cnt).toBe(2);
				expect(countB.cnt).toBe(1);
			});

			it("$tenantDataSource() returns tenant A datasource when tenant A is active", function() {
				request.wheels.tenant = {id = "tenant_a", dataSource = dsA, config = {}, "$locked" = true};

				var ds = application.wo.$tenantDataSource();
				expect(ds).toBe(dsA);

				// Verify we can read tenant A data
				var rows = QueryExecute("SELECT name FROM mt_products ORDER BY name", [], {datasource = ds});
				expect(rows.recordCount).toBe(2);
				expect(rows.name[1]).toBe("Widget-A");
			});

			it("$tenantDataSource() returns tenant B datasource when tenant B is active", function() {
				request.wheels.tenant = {id = "tenant_b", dataSource = dsB, config = {}, "$locked" = true};

				var ds = application.wo.$tenantDataSource();
				expect(ds).toBe(dsB);

				// Verify we can read tenant B data
				var rows = QueryExecute("SELECT name FROM mt_products ORDER BY name", [], {datasource = ds});
				expect(rows.recordCount).toBe(1);
				expect(rows.name[1]).toBe("Gadget-B");
			});

			it("write to tenant B does not affect tenant A", function() {
				request.wheels.tenant = {id = "tenant_b", dataSource = dsB, config = {}, "$locked" = true};

				var ds = application.wo.$tenantDataSource();
				QueryExecute(
					"INSERT INTO mt_products (name, price) VALUES ('NewItem-B', 99.99)",
					[],
					{datasource = ds}
				);

				// Verify it landed in B
				var countB = QueryExecute("SELECT COUNT(*) AS cnt FROM mt_products", [], {datasource = dsB});
				expect(countB.cnt).toBe(2);

				// Verify A is untouched
				var countA = QueryExecute("SELECT COUNT(*) AS cnt FROM mt_products", [], {datasource = dsA});
				expect(countA.cnt).toBe(2);
			});

			it("TenantResolver with header strategy routes to correct datasource", function() {
				// Build a resolver that maps header value to datasource
				var tenantDsA = dsA;
				var tenantDsB = dsB;
				var resolver = function(req) {
					var tenantId = "";
					if (StructKeyExists(req, "$tenantHeaderValue")) {
						tenantId = req.$tenantHeaderValue;
					} else if (StructKeyExists(req, "cgi") && StructKeyExists(req.cgi, "http_x_tenant_id")) {
						tenantId = req.cgi.http_x_tenant_id;
					}
					if (tenantId == "tenant_a") return {id = "tenant_a", dataSource = tenantDsA};
					if (tenantId == "tenant_b") return {id = "tenant_b", dataSource = tenantDsB};
					return {};
				};

				var mw = new wheels.middleware.TenantResolver(
					strategy = "header",
					headerName = "X-Tenant-ID",
					resolver = resolver
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

				// --- Request as Tenant A ---
				var resultA = {ds = "", count = 0};
				var handlerA = function(required struct request) {
					if (IsDefined("request.wheels.tenant")) {
						resultA.ds = request.wheels.tenant.dataSource;
						var rows = QueryExecute("SELECT COUNT(*) AS cnt FROM mt_products", [], {datasource = resultA.ds});
						resultA.count = rows.cnt;
					}
					return "ok";
				};
				pipeline.run(
					request = {cgi = {http_x_tenant_id = "tenant_a"}},
					coreHandler = handlerA
				);

				expect(resultA.ds).toBe(dsA);
				expect(resultA.count).toBe(2);

				// --- Request as Tenant B ---
				var resultB = {ds = "", count = 0};
				var handlerB = function(required struct request) {
					if (IsDefined("request.wheels.tenant")) {
						resultB.ds = request.wheels.tenant.dataSource;
						var rows = QueryExecute("SELECT COUNT(*) AS cnt FROM mt_products", [], {datasource = resultB.ds});
						resultB.count = rows.cnt;
					}
					return "ok";
				};
				pipeline.run(
					request = {cgi = {http_x_tenant_id = "tenant_b"}},
					coreHandler = handlerB
				);

				expect(resultB.ds).toBe(dsB);
				expect(resultB.count).toBeGTE(1);
			});

			it("no tenant header means no tenant context is set", function() {
				var mw = new wheels.middleware.TenantResolver(
					strategy = "header",
					headerName = "X-Tenant-ID",
					resolver = function(req) {
						return {id = "x", dataSource = dsB};
					}
				);
				var pipeline = new wheels.middleware.Pipeline(middleware = [mw]);

				var result = {hasTenant = false};
				var handler = function(required struct request) {
					result.hasTenant = IsDefined("request.wheels.tenant");
					return "ok";
				};
				pipeline.run(
					request = {cgi = {}},
					coreHandler = handler
				);

				expect(result.hasTenant).toBeFalse();
			});

			it("$tenantDataSource() returns default DS when no tenant is active", function() {
				StructDelete(request.wheels, "tenant");
				var ds = application.wo.$tenantDataSource();
				expect(ds).toBe(application.wheels.dataSourceName);
			});

			it("per-tenant config override works in $get()", function() {
				request.wheels.tenant = {
					id = "tenant_a",
					dataSource = dsA,
					config = {appName = "Tenant A App"},
					"$locked" = true
				};

				var val = application.wo.$get("appName");
				expect(val).toBe("Tenant A App");
			});

			it("per-tenant config cannot override security-sensitive settings", function() {
				request.wheels.tenant = {
					id = "tenant_a",
					dataSource = dsA,
					config = {encryptionAlgorithm = "none", reloadPassword = "hacked"},
					"$locked" = true
				};

				// These should return the application-level values, not the tenant overrides
				var algo = application.wo.$get("encryptionAlgorithm");
				expect(algo).notToBe("none");

				var pwd = application.wo.$get("reloadPassword");
				expect(pwd).notToBe("hacked");
			});

		});
	}

}
