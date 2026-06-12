/**
 * Structural guard for issue ##3054.
 *
 * vendor/wheels/events/onapplicationstart.cfc is a plain `component {` — no
 * extends, no mixins — so framework $-helpers (Global.cfc and friends) are NOT
 * in its function scope. Every helper call in that file must go through
 * application.wo (the DI "global" instance). A single bare $location() in the
 * redirectAfterReload block threw "No matching function [$LOCATION] found"
 * during the post-switch cold start, which 500'd the request and silently
 * reverted URL environment switches into production and maintenance — exactly
 * the two targets that auto-enable redirectAfterReload (events/init/orm.cfm).
 * The call had been latent since the Dec 2024 lifecycle restructure and only
 * became reachable when ##3036 made the restart redirect preserve the
 * reload/password parameters.
 *
 * Fixing the resolution alone is not enough: cflocation aborts the request
 * while onApplicationStart is still running, the engine then discards the
 * half-started application, and the next request cold-starts back into the
 * file-configured environment (verified live on Lucee 7 — the switch engaged,
 * the redirect fired, and the environment still reverted). The fix therefore
 * DEFERS the redirect: onApplicationStart stashes the stripped URL on the
 * request scope and EventMethods.$runOnRequestStart — which runs in the same
 * request after the new application has been persisted — performs the
 * $location() call, where it resolves via the Global.cfc inheritance chain.
 *
 * The throwing/reverting path runs inside onApplicationStart of a
 * cold-starting application, so it cannot execute inside a spec; the
 * practical gate is structural (same approach as
 * security/BareCfabortGuardSpec.cfc: line-anchored, comment-prefix skipping,
 * deliberately NOT a global comment-strip regex — that shape hangs Lucee 7 on
 * large sources), plus the cheap executable half pinning that the deferred
 * call's receiver actually resolves $location().
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("onapplicationstart.cfc helper resolution (issue ##3054)", () => {

			it("contains no bare $-helper calls that cannot resolve in its mixin-free scope", () => {
				var filePath = ExpandPath("/wheels/events/onapplicationstart.cfc");
				var content = FileRead(filePath);

				// Function names defined IN the file (e.g. $init,
				// $resolveAllowEnvironmentSwitchViaUrl) are legal to call bare.
				var localNames = {};
				var definitionMatches = REMatchNoCase("function\s+\$\w+", content);
				for (var definition in definitionMatches) {
					localNames[REReplaceNoCase(definition, "function\s+", "")] = true;
				}

				// Bare-call shape: $name( NOT preceded by a dot (dotted calls like
				// application.wo.$createObjectFromRoot( resolve on the receiver) and
				// not part of a longer identifier. Group 2 captures the helper name.
				var barePattern = "(^|[^.\w$])(\$\w+)\s*\(";

				var offenders = [];
				// includeEmptyFields=true keeps blank lines so reported line
				// numbers match the actual source.
				var fileLines = ListToArray(content, Chr(10), true);
				var lineNumber = 0;
				for (var rawLine in fileLines) {
					lineNumber++;
					var trimmed = Trim(Replace(rawLine, Chr(13), "", "all"));
					// Skip comment-only lines (line comments and block-comment
					// bodies); $-helper mentions in prose are not calls.
					if (Left(trimmed, 2) == "//" || Left(trimmed, 1) == "*" || Left(trimmed, 2) == "/*") {
						continue;
					}
					var found = REFindNoCase(barePattern, trimmed, 1, true);
					while (found.pos[1] > 0) {
						var helperName = Mid(trimmed, found.pos[3], found.len[3]);
						if (!StructKeyExists(localNames, helperName)) {
							ArrayAppend(offenders, "#helperName# at line #lineNumber#");
						}
						found = REFindNoCase(barePattern, trimmed, found.pos[1] + found.len[1], true);
					}
				}

				expect(ArrayLen(offenders)).toBe(
					0,
					"Bare $-helper call(s) in events/onapplicationstart.cfc: #ArrayToList(offenders, ', ')#. "
					& "That file is a plain component with no extends and no mixins — framework helpers "
					& "only resolve through application.wo there. A bare call throws 'No matching "
					& "function' during application start, 500s the request, and silently reverts URL "
					& "environment switches (issue ##3054)."
				);
			});

			it("defers the redirect-after-reload out of onApplicationStart via the request scope", () => {
				var stashKey = "request.wheels.redirectAfterReloadUrl";

				// Producer: the redirectAfterReload block stashes the stripped URL
				// instead of redirecting mid-onApplicationStart (a cflocation there
				// makes the engine discard the half-started application and the
				// environment switch silently reverts).
				var producer = FileRead(ExpandPath("/wheels/events/onapplicationstart.cfc"));
				expect(FindNoCase("#stashKey# =", producer) > 0).toBeTrue(
					"events/onapplicationstart.cfc no longer stashes #stashKey# in the "
					& "redirectAfterReload block. Redirecting directly from onApplicationStart "
					& "discards the new application and reverts URL environment switches into "
					& "production/maintenance (issue ##3054)."
				);

				// Consumer: $runOnRequestStart performs the deferred $location() in the
				// same request, after the new application has been persisted.
				var consumer = FileRead(ExpandPath("/wheels/events/EventMethods.cfc"));
				expect(FindNoCase('StructDelete(request.wheels, "redirectAfterReloadUrl")', consumer) > 0).toBeTrue(
					"events/EventMethods.cfc##$runOnRequestStart no longer consumes "
					& "#stashKey# — the deferred redirect-after-reload would never fire "
					& "(issue ##3054)."
				);
			});

			it("resolves $location on EventMethods, the receiver of the deferred redirect", () => {
				// EventMethods extends wheels.Global, where $location() lives. Pin the
				// inheritance so the deferred call cannot regress into an
				// unresolvable shape like the original bare call.
				var eventMethods = CreateObject("component", "wheels.events.EventMethods");
				expect(StructKeyExists(eventMethods, "$location")).toBeTrue(
					"wheels.events.EventMethods does not resolve $location() — the deferred "
					& "redirect-after-reload in $runOnRequestStart depends on it (issue ##3054)."
				);
			});

		});

	}

}
