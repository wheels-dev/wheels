(function () {
	var activePanel = null;

	function debugRoot() {
		return document.getElementById('wheels-debugbar');
	}

	function syncPageInset() {
		var root = debugRoot();
		var html = document.documentElement;
		if (!html) return;
		var insetPx = '0px';
		if (root && !root.classList.contains('wdb-collapsed')) {
			var measured = root.offsetHeight;
			insetPx = (measured > 0 ? measured : 36) + 'px';
			html.classList.add('wdb-has-debugbar');
			html.classList.remove('wdb-debugbar-collapsed');
		} else if (root) {
			html.classList.add('wdb-has-debugbar');
			html.classList.add('wdb-debugbar-collapsed');
		}
		html.style.setProperty('--wdb-inset', insetPx);
	}

	function setCollapsed(collapsed, animate) {
		var root = debugRoot();
		if (!root) return;
		if (!animate) {
			root.classList.add('wdb-no-transition');
		}
		if (collapsed) {
			root.classList.add('wdb-collapsed');
		} else {
			root.classList.remove('wdb-collapsed');
		}
		var logo = root.querySelector('.wdb-logo');
		if (logo) {
			logo.title = collapsed ? 'Show Debug Bar' : 'Request Details';
		}
		if (!animate) {
			root.offsetWidth;
			root.classList.remove('wdb-no-transition');
		}
		syncPageInset();
		try {
			if (collapsed) {
				sessionStorage.setItem('wdb-hidden', '1');
			} else {
				sessionStorage.removeItem('wdb-hidden');
			}
		} catch (e) {}
	}

	window.wdbToggle = function (name) {
		var root = debugRoot();
		if (root && root.classList.contains('wdb-collapsed')) {
			return;
		}
		var panels = document.querySelectorAll('#wheels-debugbar .wdb-panel');
		var tabs = document.querySelectorAll('#wheels-debugbar .wdb-tab');
		if (activePanel === name) {
			wdbClosePanel();
			return;
		}
		for (var i = 0; i < panels.length; i++) panels[i].classList.remove('open');
		var p = document.getElementById('wdb-panel-' + name);
		if (p) p.classList.add('open');
		for (var j = 0; j < tabs.length; j++) tabs[j].classList.remove('active');
		var t = document.getElementById('wdb-tab-' + name);
		if (t) t.classList.add('active');
		activePanel = name;
		// Migration state can change between opens (a CLI run, another tab),
		// so refresh every time rather than once per page load. The suite is
		// re-run on each open for the same reason, starting from the full sweep
		// so a previous single-bundle filter does not stick.
		if (name === 'migrator' && window.wdbMigratorLoad) window.wdbMigratorLoad();
		if (name === 'tests' && window.wdbTestsLoad) window.wdbTestsLoad();
		if (name === 'packages' && window.wdbPackagesLoad) window.wdbPackagesLoad();
	};
	window.wdbClosePanel = function () {
		var panels = document.querySelectorAll('#wheels-debugbar .wdb-panel');
		var tabs = document.querySelectorAll('#wheels-debugbar .wdb-tab');
		for (var i = 0; i < panels.length; i++) panels[i].classList.remove('open');
		for (var j = 0; j < tabs.length; j++) tabs[j].classList.remove('active');
		activePanel = null;
	};
	window.wdbLogoClick = function () {
		var root = debugRoot();
		if (root && root.classList.contains('wdb-collapsed')) {
			wdbRestore();
			return;
		}
		wdbToggle('request');
	};
	window.wdbMinimize = function () {
		wdbClosePanel();
		setCollapsed(true, true);
	};
	window.wdbRestore = function () {
		setCollapsed(false, true);
	};
	window.wdbEnvSwitch = function (el) {
		var target = el.getAttribute('data-wdb-reload');
		if (!target) return false;
		var pw = window.prompt('Enter the reload password to switch environments:');
		if (pw === null || pw === '') return false;
		window.location.href = target + '&password=' + encodeURIComponent(pw);
		return false;
	};

	// ── Lazy panels ──────────────────────────────────────────────────────
	// Migration status costs a database round-trip and System Info reads JDBC
	// metadata, so neither is rendered into every response. Both load the
	// first time the developer actually asks for them.
	var migToken = '';
	var migLastState = null;
	var migLastAction = null;
	var migCopyPayload = '';
	var sysinfoLoaded = false;

	// Lucee upper-cases struct keys when serialising to JSON; Adobe preserves
	// them. Read case-insensitively so the same payload works on both.
	function pick(obj, name) {
		if (!obj) return undefined;
		if (Object.prototype.hasOwnProperty.call(obj, name)) return obj[name];
		var up = name.toUpperCase();
		if (Object.prototype.hasOwnProperty.call(obj, up)) return obj[up];
		return undefined;
	}

	function esc(v) {
		return String(v === undefined || v === null ? '' : v)
			.replace(/&/g, '&amp;').replace(/</g, '&lt;')
			.replace(/>/g, '&gt;').replace(/"/g, '&quot;');
	}

	function migUrl(tpl, version) {
		return tpl.replace('_V_', encodeURIComponent(version));
	}

	// Destructive actions ask for a sustained press rather than a click, so a
	// stray tap cannot drop tables. The fill animates as the progress bar.
	function wireHold(btn, onDone) {
		if (!btn) return;
		var ms = 1100;
		var fill = btn.querySelector('.wdb-hold-fill');
		var timer = null, fired = false;

		function start(e) {
			if (e) e.preventDefault();
			if (fired) return;
			btn.classList.add('holding');
			if (fill) {
				fill.style.transition = 'width ' + ms + 'ms linear';
				fill.style.width = '100%';
			}
			timer = setTimeout(function () {
				fired = true;
				btn.classList.remove('holding');
				var lbl = btn.querySelector('.wdb-hold-label');
				if (lbl) lbl.textContent = 'Migrating\u2026';
				onDone();
			}, ms);
		}
		function cancel() {
			if (fired) return;
			if (timer) { clearTimeout(timer); timer = null; }
			btn.classList.remove('holding');
			if (fill) {
				fill.style.transition = 'width 140ms ease';
				fill.style.width = '0%';
			}
		}
		btn.addEventListener('pointerdown', start);
		btn.addEventListener('pointerup', cancel);
		btn.addEventListener('pointerleave', cancel);
		btn.addEventListener('pointercancel', cancel);
		btn.addEventListener('contextmenu', function (e) { e.preventDefault(); });
	}

	function migFetch(url, done) {
		var cfg = window.wdbMigrator || {};
		var opts = { headers: { 'X-Wheels-Csrf-Token': migToken } };
		if (cfg.method === 'post') opts.method = 'POST';
		return fetch(url, opts).then(function (r) { return r.text(); })
			.then(done)
			.catch(function (e) {
				var b = document.getElementById('wdb-mig-result');
				if (b) { b.style.display = 'block'; b.textContent = 'Request failed: ' + e; }
			});
	}

	function migRender(payload) {
		var m = payload.migrator || {};
		var migs = pick(m, 'migrations') || [];
		var migrated = pick(m, 'migratedCount') || 0;
		var pending = pick(m, 'pendingCount') || 0;

		var head = document.getElementById('wdb-mig-headline');
		if (head) {
			head.textContent = migrated + ' applied' + (pending ? ' \u00b7 ' + pending + ' pending' : ' \u00b7 up to date');
		}

		var body = document.getElementById('wdb-mig-body');
		if (!body) return;

		if (pick(m, 'datasourceAvailable') === false) {
			body.innerHTML = '<p class="wdb-muted">Datasource unavailable: ' + esc(pick(m, 'error')) + '</p>';
			return;
		}
		if (!migs.length) {
			body.innerHTML = '<p class="wdb-muted">No migrations yet. Create one with <code>wheels g migration</code>.</p>';
			return;
		}

		var latest = null, i;
		for (i = 0; i < migs.length; i++) {
			var v = pick(migs[i], 'version');
			if (latest === null || String(v) > String(latest)) latest = v;
		}
		var current = pick(m, 'currentVersion');

		var html = '<table class="wdb-table"><tr><th>Version</th><th>Name</th><th>State</th><th></th></tr>';
		for (i = 0; i < migs.length; i++) {
			var mig = migs[i];
			var ver = pick(mig, 'version');
			var applied = String(pick(mig, 'status') || '') === 'migrated';
			// Anything applied below the current version can be rolled back to,
			// which is the only way to step down to a chosen point short of
			// resetting the whole database.
			var canRollBack = applied && String(ver) < String(current);
			var actions = '';
			if (applied) {
				if (canRollBack) {
					actions += '<button class="wdb-mig-btn wdb-mig-btn-danger" '
						+ 'onclick="wdbMigratorAction(\'migrateTo\',\'' + esc(ver) + '\',true)">Roll back to here</button> ';
				}
				actions += '<button class="wdb-mig-btn" '
					+ 'onclick="wdbMigratorAction(\'redo\',\'' + esc(ver) + '\',true)">Redo</button>';
			} else {
				actions += '<button class="wdb-mig-btn" '
					+ 'onclick="wdbMigratorAction(\'migrateTo\',\'' + esc(ver) + '\')">Run</button>';
			}
			html += '<tr><td><code>' + esc(ver) + '</code></td>'
				+ '<td>' + esc(pick(mig, 'name')) + '</td>'
				+ '<td>' + (applied
					? '<span class="wdb-badge wdb-badge-green">applied</span>'
					: '<span class="wdb-badge wdb-badge-yellow">pending</span>') + '</td>'
				+ '<td class="wdb-mig-actions">' + actions + '</td></tr>';
		}
		html += '</table>';

		html += '<div class="wdb-mig-toolbar">'
			+ '<button class="wdb-mig-btn wdb-mig-btn-primary" onclick="wdbMigratorAction(\'migrateTo\',\'' + esc(latest) + '\')">'
			+ (pending ? 'Migrate to latest' : 'Re-run to latest') + '</button>'
			+ '<button class="wdb-mig-btn wdb-mig-btn-danger" onclick="wdbMigratorAction(\'migrateTo\',\'0\',true)">Reset to 0</button>'
			+ '</div>';

		body.innerHTML = html;
	}

	window.wdbMigratorLoad = function () {
		var cfg = window.wdbMigrator;
		if (!cfg) return;
		return fetch(cfg.stateUrl)
			.then(function (r) { return r.json(); })
			.then(function (d) {
				migToken = d.csrfToken || '';
				migLastState = d;
				migRender(d);
			})
			.catch(function () {
				var b = document.getElementById('wdb-mig-body');
				if (b) b.innerHTML = '<p class="wdb-muted">Could not load migration state.</p>';
			});
	};

	window.wdbMigratorAction = function (kind, version, destructive) {
		var cfg = window.wdbMigrator;
		if (!cfg) return;
		var url = migUrl(kind === 'redo' ? cfg.redo : cfg.migrateTo, version);
		var box = document.getElementById('wdb-mig-confirm');
		var out = document.getElementById('wdb-mig-result');
		if (out) { out.style.display = 'none'; out.innerHTML = ''; }

		// Two-phase on purpose: the command endpoint returns its own wording
		// and refuses to act unless confirm=1 is supplied, so a schema change
		// is always the second, explicit step.
		migFetch(url, function (html) {
			var match = html.match(/Confirmation Required:\s*([^<]+)/);
			if (!box) return;

			var goHtml = destructive
				? '<button class="wdb-hold" id="wdb-mig-go" title="Press and hold for ~1 second">'
					+ '<span class="wdb-hold-fill"></span>'
					+ '<span class="wdb-hold-label">Hold to confirm</span></button>'
				: '<button class="wdb-mig-btn wdb-mig-btn-primary" id="wdb-mig-go">Run it</button>';

			box.style.display = 'block';
			box.innerHTML = '<p>' + esc(match ? match[1].trim() : 'Run this migration command?') + '</p>'
				+ (destructive ? '<p class="wdb-hold-hint">Destructive \u2014 press and hold, or Cancel.</p>' : '')
				+ '<div class="wdb-mig-toolbar">' + goHtml
				+ '<button class="wdb-mig-btn" id="wdb-mig-cancel">Cancel</button></div>';

			document.getElementById('wdb-mig-cancel').onclick = function () {
				box.style.display = 'none';
				box.innerHTML = '';
			};

			function execute() {
				migFetch(url + (url.indexOf('?') >= 0 ? '&' : '?') + 'confirm=1', function (result) {
					box.style.display = 'none';
					box.innerHTML = '';
					migRenderResult(result, { version: version, name: migNameFor(version), url: url });
					wdbMigratorLoad();
				});
			}

			var go = document.getElementById('wdb-mig-go');
			if (destructive) {
				wireHold(go, execute);
			} else {
				go.onclick = execute;
			}
		});
	};

	function migNameFor(version) {
		var migs = pick((migLastState || {}).migrator || {}, 'migrations') || [];
		for (var i = 0; i < migs.length; i++) {
			if (String(pick(migs[i], 'version')) === String(version)) return pick(migs[i], 'name') || '';
		}
		return '';
	}

	// The command endpoint returns its output as a <pre><code> fragment, and
	// phrases failures as "Error migrating to X" / "Migration failed to load:".
	// Rendering that in the same green block as success output made a failure
	// read as a win, so classify it: errors get their own treatment plus a copy
	// button, since these get pasted straight into an agent harness.
	function migRenderResult(html, ctx) {
		var out = document.getElementById('wdb-mig-result');
		if (!out) return;

		var tmp = document.createElement('div');
		tmp.innerHTML = String(html).replace(/<script[\s\S]*?<\/script>/gi, '');
		var pre = tmp.querySelector('pre');
		var text = ((pre ? pre.textContent : tmp.textContent) || '').replace(/\s+$/, '');

		var failed = /error migrating|migration failed|invalid syntax|\bexception\b/i.test(text);
		var st = migLastState || {};
		var mig = st.migrator || {};
		var info = ctx || migLastAction || {};

		if (failed) {
			// Front-load the context an agent needs; the raw output alone is
			// missing which migration failed and where it was run from.
			migCopyPayload = [
				'Wheels migration failed',
				'',
				'Target:   ' + (info.version || ''),
				'Name:     ' + (info.name || ''),
				'From:     ' + (pick(mig, 'currentVersion') || ''),
				'URL:      ' + (info.url || ''),
				'',
				text
			].join('\n');
		} else {
			migCopyPayload = text;
		}

		out.style.display = 'block';
		out.className = 'wdb-mig-result' + (failed ? ' wdb-mig-result-failed' : '');
		out.innerHTML = '<div class="wdb-result-head">'
			+ '<span class="wdb-result-badge' + (failed ? '' : ' wdb-result-badge-ok') + '">'
			+ (failed ? 'Migration failed' : 'Migration complete') + '</span>'
			+ '<button class="wdb-mig-btn wdb-copy-btn" onclick="wdbCopyMigrationError()">'
			+ (failed ? 'Copy error' : 'Copy') + '</button></div>'
			+ '<pre><code>' + esc(text) + '</code></pre>';
	}

	function fallbackCopy(text, done) {
		var ta = document.createElement('textarea');
		ta.value = text;
		ta.setAttribute('readonly', '');
		ta.style.position = 'fixed';
		ta.style.left = '-9999px';
		document.body.appendChild(ta);
		ta.select();
		try { document.execCommand('copy'); done(); } catch (e) {}
		document.body.removeChild(ta);
	}

	// Shared by every copy affordance in the bar, so the "Copied" feedback and
	// the clipboard fallback behave identically everywhere.
	function copyText(text, btn) {
		function done() {
			if (!btn) return;
			var old = btn.getAttribute('data-wdb-label') || btn.textContent;
			btn.setAttribute('data-wdb-label', old);
			btn.textContent = 'Copied';
			btn.classList.add('wdb-copied');
			setTimeout(function () {
				btn.textContent = old;
				btn.classList.remove('wdb-copied');
			}, 1400);
		}
		if (navigator.clipboard && navigator.clipboard.writeText) {
			navigator.clipboard.writeText(text).then(done, function () { fallbackCopy(text, done); });
		} else {
			fallbackCopy(text, done);
		}
	}

	window.wdbCopyMigrationError = function () {
		copyText(migCopyPayload, document.querySelector('#wdb-mig-result .wdb-copy-btn'));
	};

	// Copy the visible text of a block, optionally preceded by a context
	// header — enough to paste straight into an agent harness.
	window.wdbCopyEl = function (btn, id, header) {
		var el = document.getElementById(id);
		if (!el) return;
		var text = (el.innerText || el.textContent || '').replace(/[ \t]+\n/g, '\n').trim();
		copyText(header ? header + '\n\n' + text : text, btn);
	};

	// ── Tests panel ──────────────────────────────────────────────────────
	// Reads the JSON format the runner already ships (public/tests/json.cfm),
	// the same way the Migrator panel reads its own JSON endpoint. That
	// endpoint answers 417 when specs fail, which fetch still resolves, so the
	// body parses either way.
	var testsCopyPayload = '';
	var testsFilter = '';

	function testsFailedSpecs(d) {
		var bundles = pick(d, 'bundleStats') || [];
		var out = [];
		for (var i = 0; i < bundles.length; i++) {
			var suites = pick(bundles[i], 'suiteStats') || [];
			for (var j = 0; j < suites.length; j++) {
				var specs = pick(suites[j], 'specStats') || [];
				for (var k = 0; k < specs.length; k++) {
					var s = specs[k];
					var status = String(pick(s, 'status') || '');
					if (status === 'Failed' || status === 'Errored') {
						out.push({
							bundle: pick(bundles[i], 'name') || '',
							spec: pick(s, 'displayName') || '',
							status: status,
							message: pick(s, 'failMessage') || pick(s, 'failDetail') || '',
							stack: pick(s, 'failStacktrace') || ''
						});
					}
				}
			}
		}
		return out;
	}

	function testsRender(d, wallMs) {
		var pass = pick(d, 'totalPass') || 0;
		var fail = pick(d, 'totalFail') || 0;
		var error = pick(d, 'totalError') || 0;
		var ms = pick(d, 'totalDuration') || 0;
		var bundles = pick(d, 'bundleStats') || [];
		var broken = fail > 0 || error > 0;

		var head = document.getElementById('wdb-tests-headline');
		if (head) {
			head.textContent = pass + ' passed'
				+ (fail ? ' \u00b7 ' + fail + ' failed' : '')
				+ (error ? ' \u00b7 ' + error + ' errored' : '')
				+ ' \u00b7 ' + ms + 'ms';
		}

		var badge = document.getElementById('wdb-tests-badge');
		if (badge) {
			badge.style.display = '';
			badge.className = 'wdb-badge ' + (broken ? 'wdb-badge-red' : 'wdb-badge-green');
			badge.textContent = broken ? String(fail + error) : String(pass);
		}

		var body = document.getElementById('wdb-tests-body');
		var result = document.getElementById('wdb-tests-result');
		if (result) { result.style.display = 'none'; result.innerHTML = ''; }
		if (!body) return;

		if (!bundles.length) {
			body.innerHTML = '<p class="wdb-muted">No test bundles found in <code>'
				+ esc(pick(d, 'directoryResolved') || 'the suite directory') + '</code>.</p>';
			return;
		}

		// A filtered run still reports every discovered bundle, with zeros for
		// the ones it skipped, so drop the empties when a filter is active.
		var shown = testsFilter
			? bundles.filter(function (b) { return (pick(b, 'totalSpecs') || 0) > 0; })
			: bundles;

		var html = '';
		if (testsFilter) {
			html += '<div class="wdb-tests-filter">Showing <strong>' + shown.length + '</strong> of '
				+ bundles.length + ' bundles \u00b7 <code>' + esc(testsFilter) + '</code> '
				+ '<button class="wdb-mig-btn" onclick="wdbTestsLoad()">Run all</button></div>';
		}
		html += '<table class="wdb-table"><tr><th>Bundle</th><th>Specs</th>'
			+ '<th>Pass</th><th>Fail</th><th>Error</th><th>Time</th><th></th></tr>';
		for (var i = 0; i < shown.length; i++) {
			var b = shown[i];
			var bf = pick(b, 'totalFail') || 0;
			var be = pick(b, 'totalError') || 0;
			html += '<tr' + ((bf || be) ? ' class="wdb-tests-bad"' : '') + '>'
				+ '<td>' + esc(pick(b, 'name')) + '</td>'
				+ '<td>' + (pick(b, 'totalSpecs') || 0) + '</td>'
				+ '<td>' + (pick(b, 'totalPass') || 0) + '</td>'
				+ '<td>' + bf + '</td>'
				+ '<td>' + be + '</td>'
				+ '<td>' + (pick(b, 'totalDuration') || 0) + 'ms</td>'
				+ '<td class="wdb-mig-actions"><button class="wdb-mig-btn" title="Run only this bundle" '
				+ 'onclick="wdbTestsLoad(\'' + esc(pick(b, 'name')) + '\')">Run</button></td></tr>';
		}
		html += '</table>';
		body.innerHTML = html;

		if (!broken || !result) return;

		// Failures first: they are what the developer opened this tab for, and
		// the whole point of the copy button is to hand them to an agent.
		var failures = testsFailedSpecs(d);
		testsCopyPayload = 'Wheels test failures\n\n'
			+ pass + ' passed, ' + fail + ' failed, ' + error + ' errored'
			+ ' (' + ms + 'ms)\n\n'
			+ failures.map(function (f) {
				return f.bundle + ' \u203a ' + f.spec + ' [' + f.status + ']\n'
					+ (f.message ? '  ' + f.message + '\n' : '')
					+ (f.stack ? '  ' + f.stack.split('\n').slice(0, 6).join('\n  ') + '\n' : '');
			}).join('\n');

		result.style.display = 'block';
		result.className = 'wdb-mig-result wdb-mig-result-failed';
		result.innerHTML = '<div class="wdb-result-head">'
			+ '<span class="wdb-result-badge">' + failures.length + ' failing spec'
			+ (failures.length === 1 ? '' : 's') + '</span>'
			+ '<button class="wdb-mig-btn wdb-copy-btn" onclick="wdbCopyTestFailures()">Copy failures</button>'
			+ '</div><pre><code>' + esc(failures.map(function (f) {
				return f.spec + '  [' + f.status + ']\n' + (f.message ? '  ' + f.message : '');
			}).join('\n\n')) + '</code></pre>';
	}

	window.wdbCopyTestFailures = function () {
		copyText(testsCopyPayload, document.querySelector('#wdb-tests-result .wdb-copy-btn'));
	};

	// "Run again" repeats whatever scope is on screen, so a single-bundle run
	// stays scoped instead of silently widening to the whole suite.
	window.wdbTestsRerun = function () {
		wdbTestsLoad(testsFilter);
	};

	window.wdbTestsLoad = function (bundle) {
		var cfg = window.wdbTests;
		if (!cfg) return;
		// `testBundles` is the framework's documented single-bundle scope —
		// `directory` only narrows to a DIRECTORY (and a single spec file
		// matches no bundles at all, #3083), while `bundles` is ignored
		// entirely (#3352). See TestDirectoryResolver.scopeWarnings().
		testsFilter = bundle || '';
		var url = cfg.runUrl
			+ (testsFilter ? '&testBundles=' + encodeURIComponent(testsFilter) : '');

		var body = document.getElementById('wdb-tests-body');
		var result = document.getElementById('wdb-tests-result');
		if (result) { result.style.display = 'none'; result.innerHTML = ''; }
		if (body) body.innerHTML = '<p class="wdb-muted">Running the suite\u2026</p>';

		return fetch(url, { headers: { 'Accept': 'application/json' } })
			.then(function (r) { return r.json(); })
			.then(function (d) { testsRender(d); })
			.catch(function () {
				if (body) body.innerHTML = '<p class="wdb-muted">Could not run the test suite.</p>';
			});
	};

	// ── Packages panel ───────────────────────────────────────────────────
	// Same shape as the others: read the JSON the framework already emits.
	// The installed list is the boring half — the *failed* list is the reason
	// to look, and it gets the same copy affordance as migration errors.
	var packagesCopyPayload = '';

	function packagesRender(d) {
		var p = pick(d, 'packages') || {};
		var loaded = pick(p, 'loaded') || {};
		var failed = pick(p, 'failed') || [];
		var names = Object.keys(loaded);

		var head = document.getElementById('wdb-packages-headline');
		if (head) {
			head.textContent = names.length + ' loaded'
				+ (failed.length ? ' \u00b7 ' + failed.length + ' failed' : '');
		}
		var badge = document.getElementById('wdb-packages-badge');
		if (badge) {
			badge.style.display = '';
			badge.className = 'wdb-badge ' + (failed.length ? 'wdb-badge-red' : 'wdb-badge-blue');
			badge.textContent = String(names.length);
		}

		var body = document.getElementById('wdb-packages-body');
		var result = document.getElementById('wdb-packages-result');
		if (result) { result.style.display = 'none'; result.innerHTML = ''; }
		if (!body) return;

		var html = '';
		if (names.length) {
			html += '<table class="wdb-table"><tr><th>Package</th><th>Version</th><th>Author</th><th>Description</th></tr>';
			for (var i = 0; i < names.length; i++) {
				var pkg = loaded[names[i]] || {};
				html += '<tr>'
					+ '<td><code>' + esc(pick(pkg, 'name') || names[i]) + '</code></td>'
					+ '<td>' + esc(pick(pkg, 'version')) + '</td>'
					+ '<td>' + esc(pick(pkg, 'author')) + '</td>'
					+ '<td class="wdb-pkg-desc">' + esc(pick(pkg, 'description')) + '</td></tr>';
			}
			html += '</table>';
		} else {
			html += '<p class="wdb-muted">No packages installed. Add one with <code>wheels packages add &lt;name&gt;</code>.</p>';
		}
		body.innerHTML = html;

		if (!failed.length || !result) return;

		packagesCopyPayload = 'Wheels package load failures\n\n'
			+ failed.map(function (f) {
				return (pick(f, 'name') || '?') + '\n  ' + (pick(f, 'error') || '')
					+ (pick(f, 'detail') ? '\n  ' + pick(f, 'detail') : '');
			}).join('\n\n');

		result.style.display = 'block';
		result.className = 'wdb-mig-result wdb-mig-result-failed';
		result.innerHTML = '<div class="wdb-result-head">'
			+ '<span class="wdb-result-badge">' + failed.length + ' package'
			+ (failed.length === 1 ? '' : 's') + ' failed to load</span>'
			+ '<button class="wdb-mig-btn wdb-copy-btn" onclick="wdbCopyPackageFailures()">Copy failures</button>'
			+ '</div><pre><code>' + esc(failed.map(function (f) {
				return (pick(f, 'name') || '?') + ': ' + (pick(f, 'error') || '');
			}).join('\n')) + '</code></pre>';
	}

	window.wdbCopyPackageFailures = function () {
		copyText(packagesCopyPayload, document.querySelector('#wdb-packages-result .wdb-copy-btn'));
	};

	window.wdbPackagesLoad = function () {
		var cfg = window.wdbPackages;
		if (!cfg) return;
		var body = document.getElementById('wdb-packages-body');
		if (body) body.innerHTML = '<p class="wdb-muted">Loading\u2026</p>';
		return fetch(cfg.stateUrl, { headers: { 'Accept': 'application/json' } })
			.then(function (r) { return r.json(); })
			.then(function (d) { packagesRender(d); })
			.catch(function () {
				if (body) body.innerHTML = '<p class="wdb-muted">Could not load packages.</p>';
			});
	};

	function kvSection(title, pairs) {		var rows = '', i;
		for (i = 0; i < pairs.length; i++) {
			var v = pairs[i][1];
			if (v === undefined || v === null || v === '') continue;
			rows += '<dt>' + esc(pairs[i][0]) + '</dt><dd>' + esc(v) + '</dd>';
		}
		if (!rows) return '';
		return '<div class="wdb-section"><div class="wdb-section-title">' + esc(title) + '</div>'
			+ '<dl class="wdb-kv">' + rows + '</dl></div>';
	}

	function wdbSysinfoLoad() {
		var el = document.getElementById('wdb-sysinfo');
		var body = document.getElementById('wdb-sysinfo-body');
		if (!el || !body || sysinfoLoaded) return;
		sysinfoLoaded = true;

		fetch(el.getAttribute('data-wdb-url'))
			.then(function (r) { return r.json(); })
			.then(function (d) {
				var s = pick(d, 'server') || {};
				var e = pick(d, 'environment') || {};
				var db = pick(d, 'database') || {};
				var app = pick(d, 'application') || {};

				var html = kvSection('Server', [
					['CFML engine', pick(s, 'cfmlEngine')],
					['Wheels version', pick(s, 'wheelsVersion')],
					['Java runtime', pick(s, 'javaRuntime')],
					['Java version', pick(s, 'javaVersion')]
				]);
				html += kvSection('Database', [
					['Datasource', pick(db, 'datasourceName')],
					['Adapter', pick(db, 'adapterName')],
					['Product', pick(db, 'productName')],
					['Version', pick(db, 'version')],
					['Driver', pick(db, 'driver')],
					['Driver version', pick(db, 'driverVersion')],
					['JDBC version', pick(db, 'jdbcVersion')]
				]);
				html += kvSection('Environment', [
					['Host name', pick(e, 'hostName')],
					['Environment', pick(e, 'environment')],
					['URL rewriting', pick(e, 'urlRewriting')],
					['Debug information', pick(e, 'showDebugInformation')],
					['Env switch via URL', pick(e, 'allowEnvironmentSwitchViaUrl')],
					['IP exceptions', pick(e, 'ipExceptions')]
				]);
				html += kvSection('Application', [
					['Name', pick(app, 'name')]
				]);

				body.innerHTML = html || '<p class="wdb-muted">No system information available.</p>';
			})
			.catch(function () {
				body.innerHTML = '<p class="wdb-muted">Could not load system information.</p>';
			});
	}
	window.wdbSysinfoLoad = wdbSysinfoLoad;

	(function () {
		var si = document.getElementById('wdb-sysinfo');
		if (si) {
			si.addEventListener('toggle', function () {
				if (si.open) wdbSysinfoLoad();
			});
		}
	})();
	// ── Tab strip density (Dock-style) ───────────────────────────────────
	// Ten tabs do not fit a narrow window. Clipping them used to push the close
	// button off-screen, and a horizontally scrolling bar gives no clue there
	// is more to see. Instead: when the labels stop fitting, drop to icons and
	// reveal each name on hover. If even the icons overflow, the bar's
	// overflow-x:auto still lets it scroll.
	function wrapTabLabels() {
		var tabs = document.querySelectorAll('#wheels-debugbar .wdb-tab');
		for (var i = 0; i < tabs.length; i++) {
			var tab = tabs[i];
			if (tab.getAttribute('data-wdb-labelled') === '1') continue;
			var label = '';
			// Walk backwards so replaceChild() cannot disturb the indices of
			// nodes still to be visited.
			for (var j = tab.childNodes.length - 1; j >= 0; j--) {
				var node = tab.childNodes[j];
				if (node.nodeType !== 3) continue;
				var text = (node.nodeValue || '').trim();
				if (!text) { tab.removeChild(node); continue; }
				label = label ? text + ' ' + label : text;
				var span = document.createElement('span');
				span.className = 'wdb-tab-label';
				span.textContent = text;
				tab.replaceChild(span, node);
			}
			if (label) {
				tab.setAttribute('data-wdb-labelled', '1');
				tab.setAttribute('data-wdb-name', label);
				// The name moves to a styled hover tooltip (see wireTips), so
				// drop the native `title` — otherwise the browser draws its own
				// after a delay and the two fight. aria-label keeps the name
				// available to assistive tech.
				tab.setAttribute('aria-label', label);
				tab.removeAttribute('title');
			}
		}
	}

	function syncTabDensity() {
		var root = debugRoot();
		if (!root) return;
		var bar = root.querySelector('.wdb-bar');
		if (!bar) return;
		// Always measure with labels showing, so widening the window restores
		// them rather than leaving the bar stuck in icon mode.
		root.classList.remove('wdb-icons');
		root.classList.toggle('wdb-icons', bar.scrollWidth > bar.clientWidth + 1);
	}

	// ── Tab tooltips ─────────────────────────────────────────────────────
	// The bar sits at the very bottom of the window, so the tip is drawn above
	// the tab and clamped to the viewport edges.
	var tipEl = null;

	function showTip(tab) {
		var name = tab.getAttribute('data-wdb-name');
		if (!name) return;
		var root = debugRoot();
		if (!root) return;
		if (!tipEl) {
			tipEl = document.createElement('div');
			tipEl.className = 'wdb-tip';
			root.appendChild(tipEl);
		}
		tipEl.textContent = name;
		tipEl.classList.add('wdb-tip-on');
		var r = tab.getBoundingClientRect();
		var t = tipEl.getBoundingClientRect();
		var left = r.left + (r.width - t.width) / 2;
		left = Math.max(6, Math.min(left, window.innerWidth - t.width - 6));
		tipEl.style.left = Math.round(left) + 'px';
		tipEl.style.top = Math.round(r.top - t.height - 6) + 'px';
	}

	function hideTip() {
		if (tipEl) tipEl.classList.remove('wdb-tip-on');
	}

	function wireTips() {
		var tabs = document.querySelectorAll('#wheels-debugbar .wdb-tab[data-wdb-name]');
		for (var i = 0; i < tabs.length; i++) {
			tabs[i].addEventListener('pointerenter', function () { showTip(this); });
			// Pointer events cover mouse, pen and touch; mouseleave is kept as
			// well because pointerleave alone did not fire reliably for a plain
			// mouse move away, leaving the tip stuck on screen.
			tabs[i].addEventListener('pointerleave', hideTip);
			tabs[i].addEventListener('mouseleave', hideTip);
			tabs[i].addEventListener('click', hideTip);
			tabs[i].addEventListener('focus', function () { showTip(this); });
			tabs[i].addEventListener('blur', hideTip);
		}
		// Belt and braces: a tip must never survive the pointer leaving the bar.
		var bar = document.querySelector('#wheels-debugbar .wdb-bar');
		if (bar) bar.addEventListener('mouseleave', hideTip);
		window.addEventListener('blur', hideTip);
	}

	wrapTabLabels();
	syncTabDensity();
	wireTips();

	// A window resize must not animate the bar to its new width — the 350ms
	// width transition exists for collapsing, and during a drag it made the bar
	// visibly lag the window edge. Snap it, then re-sync the page inset once
	// resizing stops (a scrollbar appearing or vanishing can change the layout
	// the inset was measured against).
	var resizeTimer = null;
	window.addEventListener('resize', function () {
		var root = debugRoot();
		if (root) root.classList.add('wdb-no-transition');
		clearTimeout(resizeTimer);
		resizeTimer = setTimeout(function () {
			if (root) root.classList.remove('wdb-no-transition');
			syncPageInset();
			syncTabDensity();
		}, 150);
	});

	try {
		if (sessionStorage.getItem('wdb-hidden') === '1') {
			wdbClosePanel();
			setCollapsed(true, false);
		} else {
			syncPageInset();
		}
	} catch (e) {
		syncPageInset();
	}
})();
