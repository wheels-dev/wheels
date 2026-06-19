/**
 * The /wheels/info page must never render secret-shaped settings in plaintext.
 *
 * The JSON branch always omitted `csrfCookieEncryptionSecretKey`, but the HTML
 * branch rendered it verbatim via outputSetting() -> formatSettingOutput(get()).
 * Both branches now share a single predicate, `$isProtectedSetting()`, plus a
 * display helper, `$settingDisplayValue()`, so they cannot drift.
 *
 * See the 2026-06-09 framework review (finding T3, info-secret-redaction).
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("/wheels/info secret redaction", () => {

			describe("$isProtectedSetting() predicate", () => {

				it("flags csrfCookieEncryptionSecretKey as protected", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$isProtectedSetting("csrfCookieEncryptionSecretKey")).toBeTrue();
				});

				it("flags other secret-shaped names as protected", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var secretShaped = [
						"reloadPassword",
						"myApiKey",
						"authToken",
						"smtpCredential",
						"awsCredentials",
						"signingPassphrase",
						"jwtPrivateKey",
						"clientSecret"
					];
					for (var settingName in secretShaped) {
						expect(publicCfc.$isProtectedSetting(settingName)).toBeTrue(
							"Expected `#settingName#` to be treated as a protected setting."
						);
					}
				});

				it("does not flag ordinary settings", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var ordinary = [
						"csrfStore",
						"csrfCookieName",
						"environment",
						"csrfCookieSecure",
						"dataSourceName",
						"urlRewriting"
					];
					for (var settingName in ordinary) {
						expect(publicCfc.$isProtectedSetting(settingName)).toBeFalse(
							"Expected `#settingName#` NOT to be treated as a protected setting."
						);
					}
				});

				it("does not flag accessControlAllowCredentials (CORS boolean flag, not a credential value)", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					expect(publicCfc.$isProtectedSetting("accessControlAllowCredentials")).toBeFalse(
						"accessControlAllowCredentials mirrors the Access-Control-Allow-Credentials response "
						& "header. Redacting it would garble the HTML CORS table and silently drop the key from "
						& "the JSON branch, breaking consumers that read it."
					);
				});

			});

			describe("$settingDisplayValue()", () => {

				// Shared struct (not a bare local) so the beforeEach/afterEach
				// closures reliably mutate the same state on every engine.
				var keyState = {existed = false, priorValue = ""};

				beforeEach(() => {
					keyState.existed = StructKeyExists(application.wheels, "csrfCookieEncryptionSecretKey");
					if (keyState.existed) {
						keyState.priorValue = application.wheels.csrfCookieEncryptionSecretKey;
					}
					application.wheels.csrfCookieEncryptionSecretKey = "sUpErSeCrEtTeStKeY123";
				});

				afterEach(() => {
					if (keyState.existed) {
						application.wheels.csrfCookieEncryptionSecretKey = keyState.priorValue;
					} else {
						StructDelete(application.wheels, "csrfCookieEncryptionSecretKey");
					}
				});

				it("redacts the CSRF cookie encryption secret key", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var rendered = publicCfc.$settingDisplayValue("csrfCookieEncryptionSecretKey");
					expect(Find("redacted", rendered) > 0).toBeTrue(
						"Expected the rendered value for csrfCookieEncryptionSecretKey to be redacted."
					);
					expect(Find("sUpErSeCrEtTeStKeY123", rendered)).toBe(
						0,
						"The secret value must never reach the /wheels/info output buffer."
					);
				});

				it("redacts protected settings without reading them, so an unset key cannot throw", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var rendered = publicCfc.$settingDisplayValue("someNonExistentApiKey");
					expect(Find("redacted", rendered) > 0).toBeTrue(
						"Protected settings must short-circuit to the redacted marker before any get() lookup."
					);
				});

				it("renders ordinary settings through the standard formatter", () => {
					var publicCfc = createObject("component", "wheels.Public").$init();
					var rendered = publicCfc.$settingDisplayValue("environment");
					expect(rendered).toBe(application.wheels.environment);
				});

			});

			describe("Source coverage: HTML and JSON branches share the predicate", () => {

				it("helpers.cfm outputSetting() renders via $settingDisplayValue()", () => {
					var source = FileRead(ExpandPath("/wheels/public/helpers.cfm"));
					expect(Find("$settingDisplayValue(arguments.setting", source) > 0).toBeTrue(
						"outputSetting() must render each row through $settingDisplayValue() so secret-shaped "
						& "settings are redacted on the HTML /wheels/info page."
					);
					expect(Find("formatSettingOutput(get(", source)).toBe(
						0,
						"outputSetting() must not call formatSettingOutput(get(...)) directly — that bypasses "
						& "secret redaction."
					);
				});

				it("info.cfm JSON branch uses $isProtectedSetting() instead of a hardcoded key compare", () => {
					var source = FileRead(ExpandPath("/wheels/public/views/info.cfm"));
					expect(Find("$isProtectedSetting", source) > 0).toBeTrue(
						"The JSON branch of info.cfm must filter settings through the shared "
						& "$isProtectedSetting() predicate."
					);
					expect(Find('!= "csrfCookieEncryptionSecretKey"', source)).toBe(
						0,
						"The hardcoded csrfCookieEncryptionSecretKey compare must be replaced by the shared "
						& "predicate so the HTML and JSON branches cannot drift."
					);
				});

			});

		});

	}

}
