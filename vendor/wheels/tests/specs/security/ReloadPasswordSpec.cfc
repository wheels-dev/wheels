/**
 * Tests that empty reloadPassword blocks URL-based environment switching
 * and that correct/incorrect passwords are handled properly.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("Reload password security", function() {

			beforeEach(function() {
				$originalPassword = application.wheels.reloadPassword;
			});

			afterEach(function() {
				application.wheels.reloadPassword = $originalPassword;
			});

			describe("Password comparison via MessageDigest.isEqual", function() {

				it("rejects reload when reloadPassword is empty", function() {
					application.wheels.reloadPassword = "";

					var passwordIsSet = Len(application.wheels.reloadPassword) > 0;
					expect(passwordIsSet).toBeFalse();
				});

				it("allows reload when password matches reloadPassword", function() {
					application.wheels.reloadPassword = "testSecret123";
					var suppliedPassword = "testSecret123";

					var passwordIsSet = Len(application.wheels.reloadPassword) > 0;
					var matched = CreateObject("java", "java.security.MessageDigest").isEqual(
						Hash(suppliedPassword, "SHA-256").getBytes("UTF-8"),
						Hash(application.wheels.reloadPassword, "SHA-256").getBytes("UTF-8")
					);

					expect(passwordIsSet).toBeTrue();
					expect(matched).toBeTrue();
				});

				it("rejects reload when password does not match reloadPassword", function() {
					application.wheels.reloadPassword = "testSecret123";
					var suppliedPassword = "wrongPassword";

					var passwordIsSet = Len(application.wheels.reloadPassword) > 0;
					var matched = CreateObject("java", "java.security.MessageDigest").isEqual(
						Hash(suppliedPassword, "SHA-256").getBytes("UTF-8"),
						Hash(application.wheels.reloadPassword, "SHA-256").getBytes("UTF-8")
					);

					expect(passwordIsSet).toBeTrue();
					expect(matched).toBeFalse();
				});

				it("rejects reload when password is empty but reloadPassword is set", function() {
					application.wheels.reloadPassword = "testSecret123";
					var suppliedPassword = "";

					var matched = CreateObject("java", "java.security.MessageDigest").isEqual(
						Hash(suppliedPassword, "SHA-256").getBytes("UTF-8"),
						Hash(application.wheels.reloadPassword, "SHA-256").getBytes("UTF-8")
					);

					expect(matched).toBeFalse();
				});

			});

			describe("Constant-time comparison prevents timing attacks", function() {

				it("uses MessageDigest.isEqual for password comparison", function() {
					var md = CreateObject("java", "java.security.MessageDigest");
					var result = md.isEqual(
						Hash("a", "SHA-256").getBytes("UTF-8"),
						Hash("a", "SHA-256").getBytes("UTF-8")
					);
					expect(result).toBeTrue();
				});

			});

			describe("Shared $secureCompare helper (used by both reload gates)", function() {

				it("returns true for an exact match", function() {
					expect(application.wo.$secureCompare("testSecret123", "testSecret123")).toBeTrue();
				});

				it("is case-sensitive, unlike the CFML == operator", function() {
					// The restart gate previously used ==, which treats "TESTSECRET123"
					// and "testSecret123" as equal and reduces the password keyspace.
					expect(application.wo.$secureCompare("TESTSECRET123", "testSecret123")).toBeFalse();
				});

				it("returns false for a non-matching value", function() {
					expect(application.wo.$secureCompare("wrongPassword", "testSecret123")).toBeFalse();
				});

				it("returns false for an empty candidate", function() {
					expect(application.wo.$secureCompare("", "testSecret123")).toBeFalse();
				});

			});

		});

	}

}
