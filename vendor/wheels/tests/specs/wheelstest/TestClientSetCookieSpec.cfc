/**
 * TestClient keeps the cookies a response sets, so a session survives from one
 * request to the next. cfhttp hands Set-Cookie over in three shapes: a simple
 * value (one cookie), an array (Lucee) and a struct keyed "1", "2", … (Adobe CF).
 * A for-in over the struct walked its keys, so on Adobe no cookie was kept.
 */
component extends="wheels.WheelsTest" {

	function run() {

		describe("TestClient $absorbSetCookies", () => {

			it("keeps every cookie from Adobe's numbered struct", () => {
				var tc = new wheels.wheelstest.TestClient(testContext = false);
				tc.$absorbSetCookies({
					"Set-Cookie" = {
						"1" = "CFID=403; path=/; HttpOnly",
						"2" = "CFTOKEN=45f4-81D1; path=/; HttpOnly; Max-Age=946080000"
					}
				});
				var jar = tc.$cookieJar();
				expect(jar.CFID).toBe("403");
				expect(jar.CFTOKEN).toBe("45f4-81D1");
				expect(StructKeyExists(jar, "1")).toBeFalse();
			});

			it("keeps cookies from an array and from a single value", () => {
				var tc = new wheels.wheelstest.TestClient(testContext = false);
				tc.$absorbSetCookies({"Set-Cookie" = ["A=1; path=/", "B=2"]});
				tc.$absorbSetCookies({"Set-Cookie" = "C=3; HttpOnly"});
				var jar = tc.$cookieJar();
				expect(jar.A).toBe("1");
				expect(jar.B).toBe("2");
				expect(jar.C).toBe("3");
			});

			it("lets a later Set-Cookie for the same name win, in header order", () => {
				var tc = new wheels.wheelstest.TestClient(testContext = false);
				tc.$absorbSetCookies({"Set-Cookie" = {"2" = "S=new", "1" = "S=old", "10" = "S=newest"}});
				expect(tc.$cookieJar().S).toBe("newest");
			});

			it("ignores a response without Set-Cookie and a value without name=value", () => {
				var tc = new wheels.wheelstest.TestClient(testContext = false);
				tc.$absorbSetCookies({"Content-Type" = "text/html"});
				tc.$absorbSetCookies({"Set-Cookie" = "garbage"});
				expect(StructCount(tc.$cookieJar())).toBe(0);
			});

		});

	}

}
