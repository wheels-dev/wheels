(function () {
	var activePanel = null;
	window.wdbToggle = function (name) {
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
	};
	window.wdbClosePanel = function () {
		var panels = document.querySelectorAll('#wheels-debugbar .wdb-panel');
		var tabs = document.querySelectorAll('#wheels-debugbar .wdb-tab');
		for (var i = 0; i < panels.length; i++) panels[i].classList.remove('open');
		for (var j = 0; j < tabs.length; j++) tabs[j].classList.remove('active');
		activePanel = null;
	};
	window.wdbMinimize = function () {
		wdbClosePanel();
		document.getElementById('wheels-debugbar').style.display = 'none';
		document.getElementById('wdb-minimized').style.display = 'block';
		try { sessionStorage.setItem('wdb-hidden', '1'); } catch (e) {}
	};
	window.wdbRestore = function () {
		document.getElementById('wheels-debugbar').style.display = '';
		document.getElementById('wdb-minimized').style.display = 'none';
		try { sessionStorage.removeItem('wdb-hidden'); } catch (e) {}
	};
	window.wdbEnvSwitch = function (el) {
		var target = el.getAttribute('data-wdb-reload');
		if (!target) return false;
		var pw = window.prompt('Enter the reload password to switch environments:');
		if (pw === null || pw === '') return false;
		window.location.href = target + '&password=' + encodeURIComponent(pw);
		return false;
	};
	try { if (sessionStorage.getItem('wdb-hidden') === '1') wdbMinimize(); } catch (e) {}
})();
