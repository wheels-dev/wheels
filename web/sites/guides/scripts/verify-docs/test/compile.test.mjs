import { test } from 'node:test';
import { strict as assert } from 'node:assert';
import { runCompile, detectMode, sniffKind, buildNativeProgram } from '../drivers/compile.mjs';

const TIMEOUT = 60_000;

function block(body) {
  return { file: 'test:inline', line: 1, language: 'cfm', kind: 'compile', attrs: {}, body };
}

// ---------------------------------------------------------------------------
// Wrap-kind sniffing (pure functions — no engine spawn)
// ---------------------------------------------------------------------------

test('sniffKind classifies component declarations', () => {
  assert.equal(sniffKind('component extends="Model" {}'), 'component');
  assert.equal(sniffKind('component {\n  function config() {}\n}'), 'component');
  assert.equal(sniffKind('// a model\ncomponent extends="Model" {}'), 'component');
  assert.equal(sniffKind('/* doc */\ncomponent {}'), 'component');
  assert.equal(sniffKind('interface {\n  function handle(req, next);\n}'), 'component');
});

test('sniffKind classifies tag-syntax bodies', () => {
  assert.equal(sniffKind('<cfscript>\nmapper().end();\n</cfscript>'), 'tag');
  assert.equal(sniffKind('<!doctype html>\n<html><body></body></html>'), 'tag');
  assert.equal(sniffKind('<!--- layout --->\n<cfoutput>#title#</cfoutput>'), 'tag');
});

test('sniffKind classifies script fragments', () => {
  assert.equal(sniffKind('set(dataSourceName="myapp_dev");'), 'script');
  assert.equal(sniffKind('describe("Post", () => {});'), 'script');
  assert.equal(sniffKind('// config\nvar di = injector();'), 'script');
  // "component" appearing mid-script must not trigger the component wrap
  assert.equal(sniffKind('x = createObject("component", "Foo");'), 'script');
});

test('buildNativeProgram wraps script fragments in a never-invoked function', () => {
  const { kind, program } = buildNativeProgram('set(dataSourceName="dev");');
  assert.equal(kind, 'script');
  assert.match(program, /function __verifyDocs\w*__\(\)\s*\{/);
  assert.match(program, /set\(dataSourceName="dev"\);/);
});

test('buildNativeProgram unwraps component declarations into function shells', () => {
  const { kind, program } = buildNativeProgram(
    'component extends="Model" {\n  function config() { validatesPresenceOf("title"); }\n}',
  );
  assert.equal(kind, 'component');
  // the component header (incl. extends) is stripped; the inner body is kept
  assert.doesNotMatch(program, /extends=/);
  assert.match(program, /validatesPresenceOf\("title"\);/);
  assert.match(program, /function __verifyDocs\w*__\(\)\s*\{/);
});

test('buildNativeProgram handles multiple component declarations in one block', () => {
  const { program } = buildNativeProgram(
    'component extends="Model" { function config() { hasMany("comments"); } }\n' +
      'component extends="Controller" { function index() { posts = model("Post").findAll(); } }',
  );
  assert.match(program, /hasMany\("comments"\);/);
  assert.match(program, /findAll\(\)/);
  // two separate wrapper shells, so duplicate member names cannot collide
  const shells = program.match(/function __verifyDocs\w*__\(\)/g);
  assert.equal(shells.length, 2);
});

test('buildNativeProgram does not double-wrap tag bodies in cfscript', () => {
  const { kind, program } = buildNativeProgram('<cfscript>\nmapper().end();\n</cfscript>');
  assert.equal(kind, 'tag');
  // breaks out of the engine's implicit <cfscript> wrapper, then guards the
  // body behind <cfif false> so it compiles but never executes
  assert.match(program, /^<\/cfscript>/);
  assert.match(program, /<cfif false>/);
  assert.match(program, /<\/cfif><cfscript>$/);
});

test('buildNativeProgram reports unbalanced component braces', () => {
  const { kind, error } = buildNativeProgram('component { function broken() {');
  assert.equal(kind, 'component');
  assert.ok(error, 'expected an error for unbalanced braces');
});

// ---------------------------------------------------------------------------
// End-to-end through the engine
// ---------------------------------------------------------------------------

test('detectMode returns "native" or "fallback"', { timeout: TIMEOUT }, async () => {
  const mode = await detectMode();
  assert.ok(mode === 'native' || mode === 'fallback', `unexpected mode: ${mode}`);
});

test('runCompile passes a valid CFC block', { timeout: TIMEOUT }, async () => {
  // the canonical VALIDATION.md example — issue #3041 G1 acceptance
  const result = await runCompile(
    block('component extends="Model" { function config() { validatesPresenceOf("title"); } }'),
  );
  assert.equal(result.ok, true, `compile failed: ${result.message ?? ''}`);
});

test('runCompile passes the G1 representative WheelsTest spec', { timeout: TIMEOUT }, async () => {
  // src/content/docs/v4-0-0/testing/index.mdx:40 — issue #3041 acceptance
  const result = await runCompile(
    block(
      'component extends="wheels.WheelsTest" {\n' +
        '    function run() {\n' +
        '        describe("Post", () => {\n' +
        '            it("requires a title", () => {\n' +
        '                var post = model("Post").new();\n' +
        '                expect(post.valid()).toBeFalse();\n' +
        '                expect(post.errorsOn("title")).toBeArray();\n' +
        '            });\n' +
        '        });\n' +
        '    }\n' +
        '}',
    ),
  );
  assert.equal(result.ok, true, `compile failed: ${result.message ?? ''}`);
});

test('runCompile fails on syntactically invalid CFML', { timeout: TIMEOUT }, async () => {
  const result = await runCompile(block('component { function broken( { }'));
  assert.equal(result.ok, false);
});

test('runCompile fails a component with a real syntax error inside (native)', { timeout: TIMEOUT }, async (t) => {
  if ((await detectMode()) !== 'native') return t.skip('fallback mode: bracket check only');
  // brackets are balanced, so only a real parse catches this
  const result = await runCompile(block('component { function config() { x = ; } }'));
  assert.equal(result.ok, false);
});

test('runCompile passes a valid script snippet', { timeout: TIMEOUT }, async () => {
  const result = await runCompile(block('x = 1 + 2; writeOutput(x);'));
  assert.equal(result.ok, true, `compile failed: ${result.message ?? ''}`);
});

test('runCompile passes a G3 spec fragment (describe/it outside a component)', { timeout: TIMEOUT }, async () => {
  const result = await runCompile(
    block(
      'describe("Post", () => {\n' +
        '    it("works", () => {\n' +
        '        expect(true).toBeTrue();\n' +
        '    });\n' +
        '});',
    ),
  );
  assert.equal(result.ok, true, `compile failed: ${result.message ?? ''}`);
});

test('runCompile passes a G4 config fragment (set/mapper/injector)', { timeout: TIMEOUT }, async () => {
  const result = await runCompile(
    block('set(dataSourceName="myapp_dev");\nvar di = injector();\ndi.map("emailService").to("app.lib.EmailService").asSingleton();'),
  );
  assert.equal(result.ok, true, `compile failed: ${result.message ?? ''}`);
});

test('runCompile fails a script fragment with a syntax error (native)', { timeout: TIMEOUT }, async (t) => {
  if ((await detectMode()) !== 'native') return t.skip('fallback mode: bracket check only');
  const result = await runCompile(block('set(dataSourceName=);'));
  assert.equal(result.ok, false);
});

test('runCompile passes a G2 tag body without double-wrapping (author cfscript)', { timeout: TIMEOUT }, async () => {
  const result = await runCompile(
    block('<cfscript>\nmapper()\n    .resources("users")\n.end();\n</cfscript>'),
  );
  assert.equal(result.ok, true, `compile failed: ${result.message ?? ''}`);
});

test('runCompile passes a G2 HTML view template', { timeout: TIMEOUT }, async () => {
  const result = await runCompile(
    block(
      '<!doctype html>\n<html>\n<body>\n<cfoutput>#contentForLayout()#</cfoutput>\n</body>\n</html>',
    ),
  );
  assert.equal(result.ok, true, `compile failed: ${result.message ?? ''}`);
});

test('runCompile fails a tag body with mismatched tags (native)', { timeout: TIMEOUT }, async (t) => {
  if ((await detectMode()) !== 'native') return t.skip('fallback mode: bracket check only');
  const result = await runCompile(block('<cfif true><cfloop from="1" to="3" index="i"></cfif>'));
  assert.equal(result.ok, false);
});
