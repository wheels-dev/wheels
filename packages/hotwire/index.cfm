<h1>wheels-hotwire</h1>
<p>Hotwire infrastructure for Wheels: Turbo Drive, Turbo Frames, Turbo Streams, Stimulus, and Hotwire Native mobile support.</p>

<h2>Quick Start</h2>
<p>Add <code>##hotwireIncludes()##</code> to your layout's <code>&lt;head&gt;</code> to activate Turbo Drive and Stimulus.</p>

<h2>Helpers</h2>

<h3>Includes</h3>
<ul><li><code>hotwireIncludes()</code> — Turbo + Stimulus script tags</li></ul>

<h3>Turbo Frames</h3>
<ul>
	<li><code>turboFrame(id, [src], [loading], [target])</code> / <code>turboFrameEnd()</code></li>
</ul>

<h3>Turbo Streams</h3>
<ul>
	<li><code>turboStreamAppend(target, content)</code></li>
	<li><code>turboStreamPrepend(target, content)</code></li>
	<li><code>turboStreamReplace(target, content)</code></li>
	<li><code>turboStreamUpdate(target, content)</code></li>
	<li><code>turboStreamRemove(target)</code></li>
	<li><code>turboStreamBefore(target, content)</code></li>
	<li><code>turboStreamAfter(target, content)</code></li>
	<li><code>turboStreamRefresh()</code></li>
	<li><code>renderTurboStream(streams)</code> — controller method</li>
</ul>

<h3>Request Detection</h3>
<ul>
	<li><code>isHotwireRequest()</code> — Turbo Stream request?</li>
	<li><code>isTurboFrameRequest()</code> — Turbo Frame request?</li>
	<li><code>turboFrameRequestId()</code> — requesting frame ID</li>
	<li><code>hotwireNativeApp()</code> — Hotwire Native mobile?</li>
</ul>

<h3>Hotwire Native Navigation</h3>
<ul>
	<li><code>recedeOrRedirectTo()</code> — pop/dismiss on native, redirect on web</li>
	<li><code>refreshOrRedirectTo()</code> — refresh on native, redirect on web</li>
	<li><code>resumeOrRedirectTo()</code> — resume on native, redirect on web</li>
</ul>

<h3>Stimulus Convenience</h3>
<ul>
	<li><code>stimulusController(controllers)</code></li>
	<li><code>stimulusAction(actions)</code></li>
	<li><code>stimulusTarget(controller, name)</code></li>
	<li><code>stimulusValue(controller, name, value)</code></li>
</ul>

<h2>Companion Plugin</h2>
<p>Pair with <strong>wheels-basecoat</strong> for a complete UI component library (buttons, cards, dialogs, tables, forms) styled with shadcn/ui-quality design.</p>

<h2>Links</h2>
<ul>
	<li><a href="https://hotwired.dev/" target="_blank">Hotwire</a> · <a href="https://turbo.hotwired.dev/" target="_blank">Turbo</a> · <a href="https://stimulus.hotwired.dev/" target="_blank">Stimulus</a> · <a href="https://native.hotwired.dev/" target="_blank">Hotwire Native</a></li>
</ul>
