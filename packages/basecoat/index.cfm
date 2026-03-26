<h1>wheels-basecoat</h1>
<p>
	<a href="https://basecoatui.com/" target="_blank">Basecoat UI</a> component helpers for Wheels.
	shadcn/ui-quality design using plain HTML + Tailwind CSS. No React required.
</p>

<h2>Quick Start</h2>
<p>Add <code>##basecoatIncludes()##</code> to your layout's <code>&lt;head&gt;</code>. Then use <code>##uiButton()##</code>, <code>##uiCard()##</code>, etc. in your views.</p>

<h2>Helpers</h2>

<h3>Includes</h3>
<ul><li><code>basecoatIncludes()</code> — Basecoat CSS + Alpine.js tags</li></ul>

<h3>Buttons &amp; Badges</h3>
<ul>
	<li><code>uiButton(text, [variant], [size], [icon], [href], ...)</code></li>
	<li><code>uiBadge(text, [variant])</code></li>
</ul>

<h3>Layout</h3>
<ul>
	<li><code>uiCard()</code> / <code>uiCardHeader()</code> / <code>uiCardContent()</code> / <code>uiCardFooter()</code> / <code>uiCardEnd()</code></li>
	<li><code>uiAlert(title, description, [variant])</code></li>
	<li><code>uiSeparator()</code></li>
	<li><code>uiSidebar()</code> family</li>
</ul>

<h3>Forms</h3>
<ul>
	<li><code>uiField(label, name, [type], [value], [errorMessage], [description], ...)</code></li>
</ul>

<h3>Data Display</h3>
<ul>
	<li><code>uiTable()</code> / <code>uiTableHeader()</code> / <code>uiTableBody()</code> / <code>uiTableRow()</code> / <code>uiTableHead()</code> / <code>uiTableCell()</code> + End variants</li>
	<li><code>uiPagination(currentPage, totalPages, baseUrl)</code></li>
</ul>

<h3>Interactive</h3>
<ul>
	<li><code>uiDialog(id, title, trigger, ...)</code> / <code>uiDialogEnd()</code></li>
	<li><code>uiTabs(default)</code> / <code>uiTabList()</code> / <code>uiTabTrigger()</code> / <code>uiTabContent()</code> + End variants</li>
	<li><code>uiDropdown(trigger)</code> / <code>uiDropdownItem()</code> / <code>uiDropdownEnd()</code></li>
	<li><code>uiToast(message, [variant])</code></li>
	<li><code>uiTooltip(tip)</code> / <code>uiTooltipEnd()</code></li>
</ul>

<h3>Feedback</h3>
<ul>
	<li><code>uiProgress(value)</code></li>
	<li><code>uiSkeleton([lines], [height], [width])</code></li>
	<li><code>uiSpinner()</code></li>
</ul>

<h3>Icons</h3>
<ul><li><code>uiIcon(name, [size], [strokeWidth])</code> — Lucide SVG icons</li></ul>

<h2>Companion Plugin</h2>
<p>Pair with <strong>wheels-hotwire</strong> for Turbo Drive (instant navigation), Turbo Frames (partial page updates), Turbo Streams (multi-target updates), and Hotwire Native (mobile apps).</p>

<h2>Links</h2>
<ul>
	<li><a href="https://basecoatui.com/" target="_blank">Basecoat UI</a> · <a href="https://ui.shadcn.com/themes" target="_blank">Theme Generator</a> · <a href="https://lucide.dev/icons" target="_blank">Lucide Icons</a></li>
</ul>
