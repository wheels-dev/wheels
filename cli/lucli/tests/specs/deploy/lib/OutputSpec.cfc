component extends="wheels.wheelstest.system.BaseSpec" {

	function run() {
		describe("Output", () => {

			it("prefixes every line with [host]", () => {
				var buf = createObject("java", "java.io.ByteArrayOutputStream").init();
				var ps = createObject("java", "java.io.PrintStream").init(buf);
				var o = new cli.lucli.services.deploy.lib.Output(ps);
				o.write("host1", "hello#chr(10)#world#chr(10)#");
				var s = buf.toString();
				expect(find("[host1] hello", s)).toBeGT(0);
				expect(find("[host1] world", s)).toBeGT(0);
			});

			it("buffers partial lines until newline", () => {
				var buf = createObject("java", "java.io.ByteArrayOutputStream").init();
				var o = new cli.lucli.services.deploy.lib.Output(
					createObject("java", "java.io.PrintStream").init(buf));
				o.write("h", "part1");
				expect(buf.size()).toBe(0);
				o.write("h", "-part2#chr(10)#");
				expect(find("[h] part1-part2", buf.toString())).toBeGT(0);
			});

			it("flush() emits an unterminated buffered line", () => {
				var buf = createObject("java", "java.io.ByteArrayOutputStream").init();
				var o = new cli.lucli.services.deploy.lib.Output(
					createObject("java", "java.io.PrintStream").init(buf));
				o.write("h", "incomplete");
				expect(buf.size()).toBe(0);
				o.flush("h");
				expect(find("[h] incomplete", buf.toString())).toBeGT(0);
			});

			it("interleaves two hosts cleanly (no fragment mixing)", () => {
				var buf = createObject("java", "java.io.ByteArrayOutputStream").init();
				var o = new cli.lucli.services.deploy.lib.Output(
					createObject("java", "java.io.PrintStream").init(buf));
				o.write("h1", "one#chr(10)#");
				o.write("h2", "two#chr(10)#");
				var s = buf.toString();
				expect(find("[h1] one", s)).toBeGT(0);
				expect(find("[h2] two", s)).toBeGT(0);
			});

		});
	}

}
