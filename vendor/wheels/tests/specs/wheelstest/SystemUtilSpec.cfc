component extends="wheels.WheelsTest" {

    /**
     * Covers the wheelstest system utilities the suite never reaches
     * directly: Util (paths/slugify/arrays), Env (system settings/properties),
     * XMLConverter (array/struct/query/object-to-XML), MixerUtil
     * (start/stop + mixin injection), and BaseReporter.openInEditorURL.
     */
    function run() {

        describe("wheelstest system utilities", () => {

            describe("Util", () => {

                beforeEach(() => {
                    util = new wheels.wheelstest.system.util.Util();
                });

                it("arrayToStruct() keys the struct by position", () => {
                    var s = util.arrayToStruct(input = ["a", "b"]);
                    expect(s).toBeStruct();
                    expect(s[1]).toBe("a");
                    expect(s[2]).toBe("b");
                });

                it("getAbsolutePath() keeps absolute paths and expands relative ones", () => {
                    expect(util.getAbsolutePath(path = "/tmp")).toBe("/tmp");
                    expect(util.getAbsolutePath(path = "/wheels/tests/specs")).toInclude("wheels");
                });

                it("slugify() lowercases and replaces spaces", () => {
                    expect(util.slugify("My Test Spec")).toInclude("my-test-spec");
                });

                it("ripExtension() strips the final extension", () => {
                    expect(util.ripExtension(filename = "MySpec.cfc")).toBe("MySpec");
                    expect(util.ripExtension(filename = "archive.tar.gz")).toBe("archive.tar");
                });

                it("fileLastModified() returns a date for an existing file", () => {
                    expect(util.fileLastModified(filename = expandPath("/wheels/tests/specs/wheelstest/BaseSpecDslAliasSpec.cfc")))
                        .toBeTypeOf("date");
                });

                it("inThread() returns a boolean", () => {
                    expect(util.inThread()).toBeTypeOf("boolean");
                });

            });

            describe("Env", () => {

                beforeEach(() => {
                    env = new wheels.wheelstest.system.util.Env();
                });

                it("getSystemSetting() returns the value or the default", () => {
                    var java = env.getJavaSystem();
                    expect(env.getSystemSetting(key = "definitely_not_a_real_key_123", defaultValue = "fallback")).toBe("fallback");
                });

                it("getSystemProperty() reads JVM properties with a default", () => {
                    expect(env.getSystemProperty(key = "java.version", defaultValue = "")).notToBe("");
                    expect(env.getSystemProperty(key = "not.a.real.property", defaultValue = "dflt")).toBe("dflt");
                });

                it("getEnv() reads process env vars with a default", () => {
                    expect(env.getEnv(key = "NOT_A_REAL_ENV_VAR_123", defaultValue = "dflt")).toBe("dflt");
                });

                it("getJavaSystem() returns the java.lang.System object", () => {
                    expect(isObject(env.getJavaSystem())).toBeTrue();
                });

            });

            describe("XMLConverter", () => {

                beforeEach(() => {
                    xml = new wheels.wheelstest.system.util.XMLConverter();
                });

                it("toXML() converts a struct", () => {
                    var out = xml.toXML(data = {name = "Luis", age = 40});
                    expect(out).toInclude("<name>Luis</name>");
                    expect(out).toInclude("<age>40</age>");
                });

                it("toXML() converts an array", () => {
                    var out = xml.toXML(data = ["a", "b"]);
                    expect(out).toInclude("<item>a</item>");
                });

                it("toXML() converts a query", () => {
                    // RustCFML's query object has no currentRow member, which
                    // queryToXML relies on (upstream issue #382) — skip there.
                    var capabilities = new wheels.wheelstest.EngineCapabilities();
                    if (!capabilities.hasJvmClassLoading()) {
                        debug("Skipping: query.currentRow is undefined on this engine");
                        return;
                    }
                    var q = queryNew("id,name");
                    queryAddRow(q, {id = 1, name = "one"});
                    var out = xml.toXML(data = q);
                    expect(out).toInclude("one");
                });

                it("toXML() converts a plain value", () => {
                    var out = xml.toXML(data = "hello");
                    expect(out).toInclude("hello");
                });

                it("toXML() escapes XML-sensitive characters via safeText", () => {
                    var out = xml.toXML(data = {body = "<tag> & 'quote'"});
                    expect(out).notToInclude("<tag>");
                });

                it("toXML() supports CDATA mode", () => {
                    var out = xml.toXML(data = {body = "raw <html>"}, useCDATA = true);
                    expect(out).toInclude("<![CDATA[");
                });

            });

            describe("MixerUtil", () => {

                it("start()/stop() mix helper methods into a CFC target", () => {
                    var mixer = new wheels.wheelstest.system.util.MixerUtil();
                    // Mixin injection writes into `this`/`variables` of the
                    // invocation context — a CFC instance, not a bare struct.
                    var target = new wheels.wheelstest.system.BaseSpec();
                    mixer.start(target);

                    target.injectMixin(name = "greet", udf = function() {
                        return "hi";
                    });
                    expect(target.greet()).toBe("hi");

                    target.injectPropertyMixin(propertyName = "answer", propertyValue = 42);
                    expect(target.getPropertyMixin(name = "answer")).toBe(42);

                    expect(isStruct(target.getVariablesMixin())).toBeTrue();

                    target.removeMixin(UDFName = "greet");
                    expect(structKeyExists(target, "greet")).toBeFalse();

                    target.removePropertyMixin(propertyName = "answer");
                    expect(target.getPropertyMixin(name = "answer", defaultValue = "gone")).toBe("gone");

                    mixer.stop(target);
                    expect(structKeyExists(target, "injectMixin")).toBeFalse();
                });

                it("invokerMixin() invokes a method on the target", () => {
                    var mixer = new wheels.wheelstest.system.util.MixerUtil();
                    var target = new wheels.wheelstest.system.BaseSpec();
                    mixer.start(target);
                    target.injectMixin(name = "doubleIt", udf = function(v) {
                        return v * 2;
                    });
                    expect(target.invokerMixin(method = "doubleIt", argCollection = {v = 4})).toBe(8);
                });

            });

            describe("BaseReporter.openInEditorURL", () => {

                it("builds a vscode URL", () => {
                    var reporter = new wheels.wheelstest.system.reports.BaseReporter();
                    expect(reporter.openInEditorURL(template = "/app/User.cfc", line = 42))
                        .toBe("vscode://file//app/User.cfc:42");
                });

                it("builds a sublime URL", () => {
                    var reporter = new wheels.wheelstest.system.reports.BaseReporter();
                    expect(reporter.openInEditorURL(template = "/app/User.cfc", line = 7, editor = "sublime"))
                        .toInclude("subl://open?url=file:///app/User.cfc&line=7");
                });

                it("builds an idea URL", () => {
                    var reporter = new wheels.wheelstest.system.reports.BaseReporter();
                    expect(reporter.openInEditorURL(template = "/app/User.cfc", line = 7, editor = "idea"))
                        .toInclude("idea");
                });

            });

        });

    }

}
