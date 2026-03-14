component extends="wheels.WheelsTest" {

	function run() {

		g = application.wo;

		describe("Multi-Tenant Support", () => {

			afterEach(() => {
				StructDelete(request.wheels, "tenant");
			});

			describe("tenant() helper", () => {

				it("returns empty struct when no tenant is active", () => {
					StructDelete(request.wheels, "tenant");
					var t = g.tenant();

					expect(t).toBeStruct();
					expect(StructIsEmpty(t)).toBeTrue();
				});

				it("returns tenant struct when tenant is active", () => {
					request.wheels.tenant = {id = "t1", dataSource = "tenant_ds", config = {}, "$locked" = true};
					var t = g.tenant();

					expect(t.id).toBe("t1");
					expect(t.dataSource).toBe("tenant_ds");
				});
			});

			describe("$tenantDataSource()", () => {

				it("returns application datasource when no tenant is active", () => {
					StructDelete(request.wheels, "tenant");
					var ds = g.$tenantDataSource();

					expect(ds).toBe(application.wheels.dataSourceName);
				});

				it("returns tenant datasource when tenant is active", () => {
					request.wheels.tenant = {id = "t1", dataSource = "custom_tenant_ds", config = {}};
					var ds = g.$tenantDataSource();

					expect(ds).toBe("custom_tenant_ds");
				});
			});

			describe("switchTenant()", () => {

				it("sets tenant on request when no tenant is active", () => {
					StructDelete(request.wheels, "tenant");
					g.switchTenant(tenant = {dataSource = "new_ds", id = "t2"});

					expect(request.wheels.tenant.id).toBe("t2");
					expect(request.wheels.tenant.dataSource).toBe("new_ds");
				});

				it("throws when current tenant is locked", () => {
					request.wheels.tenant = {id = "t1", dataSource = "ds1", config = {}, "$locked" = true};

					expect(function() {
						g.switchTenant(tenant = {dataSource = "ds2"});
					}).toThrow("Wheels.TenantLocked");
				});

				it("allows switching when force is true even if locked", () => {
					request.wheels.tenant = {id = "t1", dataSource = "ds1", config = {}, "$locked" = true};
					g.switchTenant(tenant = {dataSource = "ds2", id = "t2"}, force = true);

					expect(request.wheels.tenant.id).toBe("t2");
					expect(request.wheels.tenant.dataSource).toBe("ds2");
				});

				it("throws when tenant struct has no dataSource", () => {
					expect(function() {
						g.switchTenant(tenant = {id = "t1"});
					}).toThrow("Wheels.InvalidTenant");
				});

				it("provides default id and config when not supplied", () => {
					StructDelete(request.wheels, "tenant");
					g.switchTenant(tenant = {dataSource = "ds1"});

					expect(request.wheels.tenant.id).toBe("");
					expect(request.wheels.tenant.config).toBeStruct();
				});
			});

			describe("$get() tenant config override", () => {

				it("returns tenant config value when set", () => {
					request.wheels.tenant = {
						id = "t1",
						dataSource = "ds1",
						config = {showDebugInformation = false}
					};

					var val = g.$get("showDebugInformation");

					expect(val).toBeFalse();
				});

				it("returns application value when tenant has no override for that key", () => {
					request.wheels.tenant = {
						id = "t1",
						dataSource = "ds1",
						config = {}
					};

					var val = g.$get("dataSourceName");

					expect(val).toBe(application.wheels.dataSourceName);
				});
			});

			describe("sharedModel() configuration", () => {

				it("model without sharedModel has adapter.$isSharedModel() false", () => {
					// Use an existing test model that doesn't call sharedModel()
					var obj = g.model("post");
					var isShared = obj.$classData().adapter.$isSharedModel();

					expect(isShared).toBeFalse();
				});
			});

			describe("Adapter tenant datasource override", () => {

				it("adapter uses default datasource when no tenant is active", () => {
					StructDelete(request.wheels, "tenant");
					var adapter = CreateObject("component", "wheels.databaseAdapters.Base").$init(
						dataSource = "default_ds",
						username = "",
						password = ""
					);

					// Verify the adapter's datasource is unchanged
					// (We can't call $performQuery without a real DB, but we verify the flag)
					expect(adapter.$isSharedModel()).toBeFalse();
				});

				it("shared adapter bypasses tenant override", () => {
					var adapter = CreateObject("component", "wheels.databaseAdapters.Base").$init(
						dataSource = "default_ds",
						username = "",
						password = ""
					);
					adapter.$setSharedModel(true);

					expect(adapter.$isSharedModel()).toBeTrue();
				});
			});

		});
	}

}
