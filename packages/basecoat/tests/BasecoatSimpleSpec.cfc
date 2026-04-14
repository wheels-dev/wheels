component extends="wheels.WheelsTest" {

	function beforeAll() {
		variables.bc = createObject("component", "plugins.basecoat.Basecoat").init();
	}

	function run() {
		describe("Basecoat Phase 1+2 — Simple Components", () => {

			describe("uiButton", () => {

				it("renders primary button with bare btn class", () => {
					var html = variables.bc.uiButton(text="Save");
					expect(html).toMatch('<button type="button" class="btn"');
					expect(html).toMatch(">Save<");
				});

				it("renders secondary variant", () => {
					var html = variables.bc.uiButton(text="Cancel", variant="secondary");
					expect(html).toMatch('class="btn-secondary"');
				});

				it("renders small size", () => {
					var html = variables.bc.uiButton(text="Go", size="sm");
					expect(html).toMatch('class="btn-sm"');
				});

				it("renders small destructive compound class", () => {
					var html = variables.bc.uiButton(text="Delete", variant="destructive", size="sm");
					expect(html).toMatch('class="btn-sm-destructive"');
				});

				it("renders icon-only button", () => {
					var html = variables.bc.uiButton(icon="plus");
					expect(html).toMatch('class="btn-icon"');
					expect(html).toMatch('<svg');
				});

				it("renders small icon outline compound class", () => {
					var html = variables.bc.uiButton(icon="trash", variant="outline", size="sm");
					expect(html).toMatch('class="btn-sm-icon-outline"');
				});

				it("renders as anchor when href provided", () => {
					var html = variables.bc.uiButton(text="Visit", href="/path");
					expect(html).toMatch('<a href="/path"');
					expect(html).toMatch('>Visit</a>');
				});

				it("includes data-turbo-confirm attribute", () => {
					var html = variables.bc.uiButton(text="Delete", turboConfirm="Are you sure?");
					expect(html).toMatch('data-turbo-confirm="Are you sure?"');
				});

				it("includes disabled attribute", () => {
					var html = variables.bc.uiButton(text="Save", disabled=true);
					expect(html).toMatch(" disabled");
				});

			});

			describe("uiBadge", () => {

				it("renders default badge with bare badge class", () => {
					var html = variables.bc.uiBadge(text="New");
					expect(html).toMatch('class="badge"');
					expect(html).toMatch(">New<");
				});

				it("renders secondary variant", () => {
					var html = variables.bc.uiBadge(text="Beta", variant="secondary");
					expect(html).toMatch('class="badge-secondary"');
				});

				it("renders destructive variant", () => {
					var html = variables.bc.uiBadge(text="Error", variant="destructive");
					expect(html).toMatch('class="badge-destructive"');
				});

				it("renders outline variant", () => {
					var html = variables.bc.uiBadge(text="Draft", variant="outline");
					expect(html).toMatch('class="badge-outline"');
				});

			});

			describe("uiAlert", () => {

				it("renders alert with title and description", () => {
					var html = variables.bc.uiAlert(title="Heads up", description="Something happened");
					expect(html).toMatch('role="alert"');
					expect(html).toMatch('<h5>Heads up</h5>');
					expect(html).toMatch('<div>Something happened</div>');
				});

				it("renders destructive variant with alert-destructive class", () => {
					var html = variables.bc.uiAlert(title="Error", variant="destructive");
					expect(html).toMatch('class="alert alert-destructive"');
				});

				it("includes default info icon for default variant", () => {
					var html = variables.bc.uiAlert(title="Info");
					expect(html).toMatch('<svg');
				});

			});

			describe("uiCard family", () => {

				it("renders card container", () => {
					var html = variables.bc.uiCard();
					expect(html).toMatch('class="card"');
				});

				it("renders card header with title and description", () => {
					var html = variables.bc.uiCardHeader(title="My Card", description="A subtitle");
					expect(html).toMatch('class="card-header"');
					expect(html).toMatch('<h3>My Card</h3>');
					expect(html).toMatch('<p>A subtitle</p>');
				});

				it("renders card content section", () => {
					var html = variables.bc.uiCardContent();
					expect(html).toMatch('class="card-content"');
				});

				it("renders card footer section", () => {
					var html = variables.bc.uiCardFooter();
					expect(html).toMatch('class="card-footer"');
				});

				it("uiCardEnd returns closing div", () => {
					expect(variables.bc.uiCardEnd()).toBe('</div>');
				});

			});

			describe("uiProgress", () => {

				it("renders progress bar with correct percentage", () => {
					var html = variables.bc.uiProgress(value=60);
					expect(html).toMatch('class="progress"');
					expect(html).toMatch('style="width: 60%"');
				});

			});

			describe("uiSpinner", () => {

				it("renders spinner div", () => {
					var html = variables.bc.uiSpinner();
					expect(html).toBe('<div class="spinner"></div>');
				});

			});

			describe("uiSkeleton", () => {

				it("renders single skeleton line", () => {
					var html = variables.bc.uiSkeleton();
					expect(html).toMatch('class="skeleton h-4 w-full"');
				});

				it("renders multiple skeleton lines", () => {
					var html = variables.bc.uiSkeleton(lines=3);
					expect(html).toMatch('<div class="skeleton h-4 w-full"></div>');
					expect(listLen(html, chr(10))).toBe(3);
				});

			});

			describe("uiTooltip", () => {

				it("renders tooltip span with data-tip", () => {
					var html = variables.bc.uiTooltip(tip="Helpful text");
					expect(html).toMatch('class="tooltip"');
					expect(html).toMatch('data-tip="Helpful text"');
				});

				it("uiTooltipEnd returns closing span", () => {
					expect(variables.bc.uiTooltipEnd()).toBe('</span>');
				});

			});

			describe("uiSeparator", () => {

				it("renders hr with separator class", () => {
					var html = variables.bc.uiSeparator();
					expect(html).toBe('<hr class="separator" />');
				});

			});

		});
	}

}
