/**
 * This tests Wheels Application Bootstrapping
 */
component extends="testbox.system.BaseSpec" {
    variables.checkLegacyFunctionsConfig = [
        "get",
        "patch",
        "post",
        "put",
        "delete",
        "root",
        "wildcard",
        "resource",
        "resources",
        "member",
        "collection",
        "scope",
        "constraints",
        "controller",
        "end",
        "namespace",
        "package"
	]

	function run() {


		describe("Initialization", function() {
            
            beforeEach(() => {
				config = {path = "wheels", fileName = "Mapper", method = "$init"}
        		_params = {controller = "test", action = "index"}
		        _originalRoutes = Duplicate(application.wheels.routes)
			})

            afterEach(() => {
                application.wheels.routes = _originalRoutes
            })

			it("Exposes all public API legacy functions", function(){
                m = new wheels.Mapper()
			    for ( var func in checkLegacyFunctionsConfig ) {
			        expect( isCustomFunction(m[func])).toBeTrue()
			    }
			})
            it("is a valid instance", function() {
                m = new wheels.Mapper()
                expect(m).toBeInstanceOf('wheels.Mapper')
            })

			it("Initialises with defaults", function(){
                mapper = $mapper()
		        mapper.inspect = $inspect
		        mapperVarScope = mapper.inspect()
                expect(mapperVarScope.restful).toBeTrue()
                expect(mapperVarScope.methods).toBeTrue()
			})
			it("Initialises with restful false", function(){
                mapper = $mapper(restful = false)
		        mapper.inspect = $inspect
		        mapperVarScope = mapper.inspect()
                expect(mapperVarScope.restful).toBeFalse()
                expect(mapperVarScope.methods).toBeFalse()
			})
			it("Initialises with restful false & methods true", function(){
                mapper = $mapper(restful = false, methods = true)
		        mapper.inspect = $inspect
		        mapperVarScope = mapper.inspect()
		        expect(mapperVarScope.restful).toBeFalse()
                expect(mapperVarScope.methods).toBeTrue()
			})
		})
	}

    public struct function $mapper() {
		local.args = Duplicate(config)
		StructAppend(local.args, arguments, true)
		return application.wo.$createObjectFromRoot(argumentCollection = local.args)
	}

    public struct function $inspect() {
		return variables
	}

	public void function $clearRoutes() {
		application.wheels.routes = []
	}

}
