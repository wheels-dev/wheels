component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.bc = createObject("component", "plugins.basecoat.Basecoat").init();
	}

	function run() {
		describe("Basecoat Phase 2-5 — Complex Components", () => {

			describe("uiDialog", () => {

				it("includes aria-labelledby matching generated ID", () => {
					var html = variables.bc.uiDialog(title="My Dialog");
					// Extract the dialog ID from the html — id="dlg-XXXXXXXX"
					var idMatch = reMatch('id="(dlg-[^"]+)"', html);
					expect(arrayLen(idMatch)).toBeGTE(1);
					var dlgId = reReplace(idMatch[1], 'id="([^"]+)"', "\1");
					expect(html).toMatch('aria-labelledby="#dlgId#-title"');
					expect(html).toMatch('id="#dlgId#-title"');
				});

				it("includes aria-describedby when description provided", () => {
					var html = variables.bc.uiDialog(title="T", description="Some desc");
					var idMatch = reMatch('id="(dlg-[^"]+)"', html);
					var dlgId = reReplace(idMatch[1], 'id="([^"]+)"', "\1");
					expect(html).toMatch('aria-describedby="#dlgId#-desc"');
					expect(html).toMatch('id="#dlgId#-desc"');
				});

				it("omits aria-describedby when no description", () => {
					var html = variables.bc.uiDialog(title="T");
					expect(html).notToMatch("aria-describedby");
				});

				it("renders trigger button when triggerText provided", () => {
					var html = variables.bc.uiDialog(title="T", triggerText="Open Dialog");
					expect(html).toMatch('>Open Dialog<');
					expect(html).toMatch("showModal()");
				});

				it("omits trigger button when triggerText empty", () => {
					var html = variables.bc.uiDialog(title="T");
					expect(html).notToMatch("showModal()");
				});

				it("respects explicit ID", () => {
					var html = variables.bc.uiDialog(title="T", id="my-modal");
					expect(html).toMatch('id="my-modal"');
					expect(html).toMatch('aria-labelledby="my-modal-title"');
				});

				it("uiDialogEnd includes close button with X SVG", () => {
					var html = variables.bc.uiDialogEnd();
					expect(html).toMatch('aria-label="Close dialog"');
					expect(html).toMatch("this.closest('dialog').close()");
					expect(html).toMatch('<svg');
					expect(html).toMatch('</dialog>');
				});

				it("uiDialogFooter closes section and opens footer", () => {
					expect(variables.bc.uiDialogFooter()).toBe('</section><footer>');
				});

			});

			describe("uiField", () => {

				it("renders text input with label above", () => {
					var html = variables.bc.uiField(label="Name", name="user[name]");
					expect(html).toMatch('<label for="');
					expect(html).toMatch('>Name</label>');
					expect(html).toMatch('type="text"');
					expect(html).toMatch('class="grid gap-2"');
					expect(html).toMatch('name="user[name]"');
					expect(html).toMatch('class="input"');
				});

				it("renders textarea", () => {
					var html = variables.bc.uiField(label="Bio", name="user[bio]", type="textarea");
					expect(html).toMatch('<textarea');
					expect(html).toMatch('class="textarea"');
					expect(html).toMatch('rows="4"');
				});

				it("renders select with options", () => {
					var html = variables.bc.uiField(label="Role", name="user[role]", type="select", options="admin:Administrator,user:User");
					expect(html).toMatch('<select');
					expect(html).toMatch('class="select"');
					expect(html).toMatch('value="admin"');
					expect(html).toMatch('>Administrator<');
					expect(html).toMatch('value="user"');
				});

				it("renders checkbox with label AFTER input", () => {
					var html = variables.bc.uiField(label="Active", name="user[active]", type="checkbox");
					expect(html).toMatch('class="flex items-center gap-2"');
					// input must come before label in the string
					expect(find('<input', html)).toBeLT(find('<label', html));
					expect(html).toMatch('class="checkbox"');
				});

				it("renders switch with role=switch and label after input", () => {
					var html = variables.bc.uiField(label="Enabled", name="user[enabled]", type="switch");
					expect(html).toMatch('class="flex items-center gap-2"');
					expect(html).toMatch('role="switch"');
					expect(html).toMatch('class="switch"');
					expect(find('<input', html)).toBeLT(find('<label', html));
				});

				it("error state adds border-destructive and aria-invalid", () => {
					var html = variables.bc.uiField(label="Email", name="user[email]", type="email", errorMessage="Invalid email");
					expect(html).toMatch('border-destructive');
					expect(html).toMatch('aria-invalid="true"');
					expect(html).toMatch('class="text-sm text-destructive"');
					expect(html).toMatch('>Invalid email<');
				});

				it("error paragraph uses id matching aria-describedby", () => {
					var html = variables.bc.uiField(label="Email", name="user[email]", errorMessage="Required");
					var idMatch = reMatch('id="(fld-[^"]+)"', html);
					var fldId = reReplace(idMatch[1], 'id="([^"]+)"', "\1");
					expect(html).toMatch('aria-describedby="#fldId#-error"');
					expect(html).toMatch('id="#fldId#-error"');
				});

				it("description renders when no error", () => {
					var html = variables.bc.uiField(label="Name", name="user[name]", description="Your full name");
					expect(html).toMatch('class="text-sm text-muted-foreground"');
					expect(html).toMatch('>Your full name<');
				});

				it("auto-generates unique IDs when id not supplied", () => {
					var html1 = variables.bc.uiField(label="A", name="a");
					var html2 = variables.bc.uiField(label="B", name="b");
					var id1 = reReplace(html1, '.*id="(fld-[^"]+)".*', "\1");
					var id2 = reReplace(html2, '.*id="(fld-[^"]+)".*', "\1");
					expect(id1).notToBe(id2);
				});

			});

			describe("uiTable family", () => {

				it("uiTable opens table-container and table", () => {
					var html = variables.bc.uiTable();
					expect(html).toMatch('<div class="table-container">');
					expect(html).toMatch('<table class="table">');
				});

				it("uiTableEnd closes table and container", () => {
					expect(variables.bc.uiTableEnd()).toBe('</table></div>');
				});

				it("uiTableHeader opens thead and tr", () => {
					expect(variables.bc.uiTableHeader()).toBe('<thead><tr>');
				});

				it("uiTableHeaderEnd closes tr and thead", () => {
					expect(variables.bc.uiTableHeaderEnd()).toBe('</tr></thead>');
				});

				it("uiTableHead renders th with text", () => {
					var html = variables.bc.uiTableHead(text="Name");
					expect(html).toBe('<th>Name</th>');
				});

				it("uiTableCell renders td with text", () => {
					var html = variables.bc.uiTableCell(text="Alice");
					expect(html).toBe('<td>Alice</td>');
				});

				it("uiTableCell renders td with custom class", () => {
					var html = variables.bc.uiTableCell(text="X", class="text-right");
					expect(html).toMatch('class="text-right"');
				});

			});

			describe("uiTabs family", () => {

				it("uiTabs renders tabs div with data-default", () => {
					var html = variables.bc.uiTabs(defaultTab="tab1");
					expect(html).toMatch('class="tabs"');
					expect(html).toMatch('data-default="tab1"');
				});

				it("uiTabTrigger renders button with data-value", () => {
					var html = variables.bc.uiTabTrigger(value="tab1", text="Tab One");
					expect(html).toMatch('class="tabs-trigger"');
					expect(html).toMatch('data-value="tab1"');
					expect(html).toMatch('>Tab One<');
				});

				it("uiTabContent renders content panel with data-value", () => {
					var html = variables.bc.uiTabContent(value="tab1");
					expect(html).toMatch('class="tabs-content"');
					expect(html).toMatch('data-value="tab1"');
				});

				it("uiTabList opens tabs-list div", () => {
					expect(variables.bc.uiTabList()).toMatch('class="tabs-list"');
				});

				it("uiTabsEnd returns closing div", () => {
					expect(variables.bc.uiTabsEnd()).toBe('</div>');
				});

			});

			describe("uiDropdown family", () => {

				it("uses details/summary pattern", () => {
					var html = variables.bc.uiDropdown(text="Menu");
					expect(html).toMatch('<details class="dropdown">');
					expect(html).toMatch('<summary');
					expect(html).toMatch('>Menu</summary>');
					expect(html).toMatch('<ul>');
				});

				it("uiDropdownItem renders anchor list item", () => {
					var html = variables.bc.uiDropdownItem(text="Edit", href="/edit");
					expect(html).toMatch('<li>');
					expect(html).toMatch('href="/edit"');
					expect(html).toMatch('>Edit<');
				});

				it("uiDropdownSeparator renders hr inside li", () => {
					var html = variables.bc.uiDropdownSeparator();
					expect(html).toMatch('<li>');
					expect(html).toMatch('<hr class="separator"');
				});

				it("uiDropdownEnd closes ul and details", () => {
					expect(variables.bc.uiDropdownEnd()).toBe('</ul></details>');
				});

			});

			describe("uiPagination", () => {

				it("renders pagination nav", () => {
					var html = variables.bc.uiPagination(currentPage=3, totalPages=10, baseUrl="/posts");
					expect(html).toMatch('<nav');
					expect(html).toMatch('aria-label="Pagination"');
				});

				it("disables prev on first page", () => {
					var html = variables.bc.uiPagination(currentPage=1, totalPages=5, baseUrl="/posts");
					expect(html).toMatch('opacity-50');
					// prev link should be a span, not an anchor
					expect(html).notToMatch('aria-label="Previous page"');
				});

				it("disables next on last page", () => {
					var html = variables.bc.uiPagination(currentPage=5, totalPages=5, baseUrl="/posts");
					expect(html).notToMatch('aria-label="Next page"');
				});

				it("renders page links in window", () => {
					var html = variables.bc.uiPagination(currentPage=5, totalPages=10, baseUrl="/posts", windowSize=2);
					expect(html).toMatch('page=3');
					expect(html).toMatch('page=4');
					expect(html).toMatch('page=6');
					expect(html).toMatch('page=7');
				});

				it("marks current page", () => {
					var html = variables.bc.uiPagination(currentPage=3, totalPages=10, baseUrl="/posts");
					expect(html).toMatch('aria-current="page"');
				});

			});

			describe("uiBreadcrumb family", () => {

				it("renders nav with aria-label=Breadcrumb", () => {
					var html = variables.bc.uiBreadcrumb();
					expect(html).toMatch('<nav aria-label="Breadcrumb"');
					expect(html).toMatch('<ol>');
				});

				it("renders linked breadcrumb item", () => {
					var html = variables.bc.uiBreadcrumbItem(text="Home", href="/");
					expect(html).toMatch('<a href="/"');
					expect(html).toMatch('>Home</a>');
				});

				it("renders current page without link", () => {
					var html = variables.bc.uiBreadcrumbItem(text="Settings");
					expect(html).toMatch('aria-current="page"');
					expect(html).notToMatch('<a ');
				});

				it("uiBreadcrumbSeparator renders icon inside li", () => {
					var html = variables.bc.uiBreadcrumbSeparator();
					expect(html).toMatch('<li');
					expect(html).toMatch('<svg');
				});

				it("uiBreadcrumbEnd closes ol and nav", () => {
					expect(variables.bc.uiBreadcrumbEnd()).toBe('</ol></nav>');
				});

			});

			describe("uiSidebar family", () => {

				it("renders aside.sidebar with nav", () => {
					var html = variables.bc.uiSidebar();
					expect(html).toMatch('<aside class="sidebar">');
					expect(html).toMatch('<nav>');
				});

				it("uiSidebarSection renders section heading and ul", () => {
					var html = variables.bc.uiSidebarSection(title="Main");
					expect(html).toMatch('class="sidebar-section"');
					expect(html).toMatch('<h4>Main</h4>');
					expect(html).toMatch('<ul>');
				});

				it("uiSidebarSection omits heading when title empty", () => {
					var html = variables.bc.uiSidebarSection();
					expect(html).notToMatch('<h4>');
				});

				it("uiSidebarItem renders anchor with sidebar-item class", () => {
					var html = variables.bc.uiSidebarItem(text="Dashboard", href="/dashboard");
					expect(html).toMatch('class="sidebar-item"');
					expect(html).toMatch('href="/dashboard"');
					expect(html).toMatch('>Dashboard</a>');
				});

				it("uiSidebarItem adds active class when active=true", () => {
					var html = variables.bc.uiSidebarItem(text="Reports", href="/reports", active=true);
					expect(html).toMatch('sidebar-item-active');
				});

				it("uiSidebarItem includes icon SVG when icon provided", () => {
					var html = variables.bc.uiSidebarItem(text="Trash", href="/trash", icon="trash");
					expect(html).toMatch('<svg');
				});

				it("uiSidebarEnd closes nav and aside", () => {
					expect(variables.bc.uiSidebarEnd()).toBe('</nav></aside>');
				});

			});

		});
	}

}
