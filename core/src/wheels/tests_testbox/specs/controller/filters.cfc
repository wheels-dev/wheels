component extends="wheels.Testbox" {

    function run() {

        describe("Tests that $runfilters", () => {

        	beforeEach(() => {
                params = {controller = "filters", action = "index"}
                _controller = application.wo.controller("filters", params)
        		request.filterTests = StructNew()
        	})

            it("should run public", () => {
            	_controller.$runFilters(type = "before", action = "index")
            	expect(request.filterTests).toHaveKey('pubTest')
            })
            it("should run private", () => {
            	_controller.$runFilters(type = "before", action = "index")
            	expect(request.filterTests).toHaveKey('privTest')
            })
            it("should run in order", () => {
            	_controller.$runFilters(type = "before", action = "index")
            	expect(request.filterTests).toHaveKey('test')
            	expect(request.filterTests.test).toBe('bothpubpriv')
            })
            it("should not run excluded", () => {
            	_controller.$runFilters(type = "before", action = "doNotRun")
                expect(request.filterTests).notToHaveKey('dirTest')
            })
            it("should run included only", () => {
                _controller.$runFilters(type = "before", action = "doesNotExist")
                expect(request.filterTests).notToHaveKey('pubTest')
            })
            it("should pass direct arguments", () => {
                _controller.$runFilters(type = "before", action = "index")
                expect(request.filterTests).toHaveKey('dirTest')
                expect(request.filterTests.dirTest).toBe('1')
            })
            it("should pass direct arguments", () => {
                _controller.$runFilters(type = "before", action = "index")
                expect(request.filterTests).toHaveKey('strTest')
                expect(request.filterTests.strTest).toBe('21')
            })
            it("should pass direct arguments", () => {
                _controller.$runFilters(type = "before", action = "index")
                expect(request.filterTests).toHaveKey('bothTest')
                expect(request.filterTests.bothTest).toBe('31')
            })
        })

        describe("Tests that filterchain", () => {

            it("returns correct type", () => {
                params = {controller = "dummy", action = "dummy"}
                _controller = application.wo.controller("dummy", params)
                _controller.before1 = before1
                _controller.before2 = before2
                _controller.before3 = before3
                _controller.after1 = after1
                _controller.after2 = after2
                _controller.filters(through = "before1", type = "before")
                _controller.filters(through = "before2", type = "before")
                _controller.filters(through = "before3", type = "before")
                _controller.filters(through = "after1", type = "after")
                _controller.filters(through = "after2", type = "after")

                before = _controller.filterChain("before")
                after = _controller.filterChain("after")
                all = _controller.filterChain()

                expect(before).toHaveLength(3)
                expect(before[1].through).toBe("before1")
                expect(before[2].through).toBe("before2")
                expect(before[3].through).toBe("before3")

                expect(after).toHaveLength(2)
                expect(after[1].through).toBe("after1")
                expect(after[2].through).toBe("after2")

                expect(all).toHaveLength(5)
            })
        })

        describe("Tests that filters", () => {

            it("is adding filter", () => {
                local.controller = application.wo.controller(name = "dummy")
                local.controller.setFilterChain([])
                local.args = {}
                local.args.through = "restrictAccess"
                local.controller.filters(argumentcollection = local.args)

                result = ArrayLen(local.controller.filterChain())
                expected = 1

                expect(result).toBe(expected)

                local.controller.setFilterChain([])
            })
        })

        describe("Tests that setfilterchain", () => {

            it("is valid", () => {
                params = {controller = "dummy", action = "dummy"}
                _controller = application.wo.controller("dummy", params)

                // Build filter chain through array - this is what we're testing
                myFilterChain = [
                    {through = "restrictAccess"},
                    {through = "isLoggedIn,checkIPAddress", except = "home,login"},
                    {type = "after", through = "logConversion", only = "thankYou"}
                ];
                _controller.setFilterChain(myFilterChain);
                filterChainSet = _controller.filterChain();
                // Undo test
                _controller.setFilterChain(ArrayNew(1));
                // Build filter chain through "normal" filters() function
                _controller.filters(through = "restrictAccess");
                _controller.filters(through = "isLoggedIn,checkIPAddress", except = "home,login");
                _controller.filters(type = "after", through = "logConversion", only = "thankYou");
                filterChainNormal = _controller.filterChain();
                // Undo test
                _controller.setFilterChain(ArrayNew(1));

                // Compare filter chains
                expect(ArrayLen(filterChainSet)).toBe(ArrayLen(filterChainNormal))
                expect(filterChainSet).toBe(filterChainNormal)
            })
        })
    }

    function before1() {
        return "before1"
    }

    function before2() {
        return "before2"
    }

    function before3() {
        return "before3"
    }

    function after1() {
        return "after1"
    }

    function after2() {
        return "after2"
    }
}
