/**
 * Error emails go only to a configured address. An error email carries the
 * request's scopes, so its recipient must never come from the request: the
 * framework used to default errorEmailAddress to "webmaster@" plus the last
 * two labels of the Host of whichever request started the application.
 *
 * The mailer is the OnErrorEventDouble's recording $mail(), so each spec
 * asserts who the email would have gone to without sending anything.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("error email recipient", () => {

			beforeEach(() => {
				variables.saved = {};
				for (var key in ["sendEmailOnError", "errorEmailAddress", "errorEmailToAddress", "errorEmailFromAddress"]) {
					variables.saved[key] = application.wheels[key];
				}
				variables.savedWarned = StructKeyExists(application.wheels, "$errorEmailRecipientWarned");
				StructDelete(application.wheels, "$errorEmailRecipientWarned");
				application.wheels.sendEmailOnError = true;
				application.wheels.errorEmailAddress = "";
				application.wheels.errorEmailToAddress = "";
				application.wheels.errorEmailFromAddress = "";
			});

			afterEach(() => {
				for (var key in variables.saved) {
					application.wheels[key] = variables.saved[key];
				}
				StructDelete(application.wheels, "$errorEmailRecipientWarned");
				if (variables.savedWarned) {
					application.wheels["$errorEmailRecipientWarned"] = true;
				}
			});

			it("sends nothing after a production cold start whose first request had a crafted Host", () => {
				var started = runDebugging("production", "x.attacker.tld");
				expect(started.error).toBe("");
				application.wheels.errorEmailAddress = started.settings.errorEmailAddress;
				var em = mailer();
				em.$runOnErrorSendEmail(sampleException());
				var wouldGoTo = ArrayLen(em.mailArgs) ? em.mailArgs[1].to : "";
				expect(started.settings.errorEmailAddress).toBe("", "the cold start set the recipient to [#started.settings.errorEmailAddress#]");
				expect(em.mailCalls).toBe(0, "an error email would have gone to [#wouldGoTo#]");
			});

			it("sends nothing, and warns once, when no recipient is configured", () => {
				var em = mailer();
				em.$runOnErrorSendEmail(sampleException());
				em.$runOnErrorSendEmail(sampleException());
				expect(em.mailCalls).toBe(0);
				expect(StructKeyExists(application.wheels, "$errorEmailRecipientWarned")).toBeTrue();
			});

			it("sends to a configured errorEmailAddress, from the same address", () => {
				application.wheels.errorEmailAddress = "ops@example.com";
				var em = mailer();
				em.$runOnErrorSendEmail(sampleException());
				expect(em.mailCalls).toBe(1);
				expect(em.mailArgs[1].to).toBe("ops@example.com");
				expect(em.mailArgs[1].from).toBe("ops@example.com");
			});

			it("prefers errorEmailToAddress / errorEmailFromAddress, and sends from the recipient when no sender is set", () => {
				application.wheels.errorEmailToAddress = "alerts@example.com";
				var em = mailer();
				em.$runOnErrorSendEmail(sampleException());
				expect(em.mailArgs[1].to).toBe("alerts@example.com");
				expect(em.mailArgs[1].from).toBe("alerts@example.com");

				application.wheels.errorEmailFromAddress = "noreply@example.com";
				application.wheels.errorEmailAddress = "ops@example.com";
				var em2 = mailer();
				em2.$runOnErrorSendEmail(sampleException());
				expect(em2.mailArgs[1].to).toBe("alerts@example.com");
				expect(em2.mailArgs[1].from).toBe("noreply@example.com");
			});

		});

	}

	private any function mailer() {
		return CreateObject("component", "wheels.tests._assets.events.OnErrorEventDouble").init();
	}

	private struct function sampleException() {
		return {type = "Demo.Failure", message = "sample failure", detail = ""};
	}

	/** Include debugging.cfm against a scratch application.$wheels (a cold start); returns {error, settings}. */
	private struct function runDebugging(required string environment, required string host) {
		var state = {error = "", settings = {}};
		var hadStaging = StructKeyExists(application, "$wheels");
		var savedStaging = hadStaging ? application.$wheels : {};
		var hadCgi = StructKeyExists(request, "cgi");
		var savedCgi = hadCgi ? request.cgi : {};
		var scratchCgi = hadCgi ? Duplicate(savedCgi) : {};
		scratchCgi.server_name = arguments.host;
		request.cgi = scratchCgi;
		application.$wheels = {environment = arguments.environment};
		try {
			include "/wheels/events/init/debugging.cfm";
		} catch (any e) {
			state.error = e.message;
		} finally {
			state.settings = application.$wheels;
			if (hadStaging) {
				application.$wheels = savedStaging;
			} else {
				StructDelete(application, "$wheels");
			}
			if (hadCgi) {
				request.cgi = savedCgi;
			} else {
				StructDelete(request, "cgi");
			}
		}
		return state;
	}

}
