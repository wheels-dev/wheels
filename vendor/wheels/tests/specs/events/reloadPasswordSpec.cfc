component extends="wheels.WheelsTest" {

	function run() {

		describe("Reload password hash comparison", () => {

			it("accepts correct password via hash comparison", () => {
				local.storedPassword = "mySecretPassword123";
				local.suppliedPassword = "mySecretPassword123";
				local.result = Compare(
					Hash(local.suppliedPassword, "SHA-256"),
					Hash(local.storedPassword, "SHA-256")
				);
				expect(local.result).toBe(0);
			});

			it("rejects incorrect password via hash comparison", () => {
				local.storedPassword = "mySecretPassword123";
				local.suppliedPassword = "wrongPassword";
				local.result = Compare(
					Hash(local.suppliedPassword, "SHA-256"),
					Hash(local.storedPassword, "SHA-256")
				);
				expect(local.result).notToBe(0);
			});

			it("rejects empty password when stored password is set", () => {
				local.storedPassword = "mySecretPassword123";
				local.suppliedPassword = "";
				local.result = Compare(
					Hash(local.suppliedPassword, "SHA-256"),
					Hash(local.storedPassword, "SHA-256")
				);
				expect(local.result).notToBe(0);
			});

			it("is case-sensitive for passwords", () => {
				local.storedPassword = "MyPassword";
				local.suppliedPassword = "mypassword";
				local.result = Compare(
					Hash(local.suppliedPassword, "SHA-256"),
					Hash(local.storedPassword, "SHA-256")
				);
				expect(local.result).notToBe(0);
			});


		});
	}
}
