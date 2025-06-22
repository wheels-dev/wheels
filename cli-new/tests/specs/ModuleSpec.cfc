component extends="testbox.system.BaseSpec" {
    
    function run() {
        describe("Wheels CLI Module", function() {
            
            it("should have a valid ModuleConfig.cfc", function() {
                var moduleConfig = fileExists(expandPath("/wheelscli/ModuleConfig.cfc"));
                expect(moduleConfig).toBeTrue();
            });
            
            it("should have a valid box.json", function() {
                var boxJsonPath = expandPath("/wheelscli/box.json");
                expect(fileExists(boxJsonPath)).toBeTrue();
                
                var boxJson = deserializeJSON(fileRead(boxJsonPath));
                expect(boxJson.name).toBe("wheels-cli-next");
                expect(boxJson.type).toBe("commandbox-modules");
            });
            
            it("should have required directories", function() {
                expect(directoryExists(expandPath("/wheelscli/commands"))).toBeTrue();
                expect(directoryExists(expandPath("/wheelscli/lib"))).toBeTrue();
                expect(directoryExists(expandPath("/wheelscli/templates"))).toBeTrue();
            });
            
            it("should have BaseCommand.cfc", function() {
                var baseCommand = expandPath("/wheelscli/commands/wheels/BaseCommand.cfc");
                expect(fileExists(baseCommand)).toBeTrue();
            });
            
            it("should have DatabaseService.cfc", function() {
                var dbService = expandPath("/wheelscli/lib/DatabaseService.cfc");
                expect(fileExists(dbService)).toBeTrue();
            });
            
            it("should have core commands", function() {
                expect(fileExists(expandPath("/wheelscli/commands/wheels/version.cfc"))).toBeTrue();
                expect(fileExists(expandPath("/wheelscli/commands/wheels/help.cfc"))).toBeTrue();
                expect(fileExists(expandPath("/wheelscli/commands/wheels/create/app.cfc"))).toBeTrue();
                expect(fileExists(expandPath("/wheelscli/commands/wheels/create/model.cfc"))).toBeTrue();
            });
            
            it("should have model templates", function() {
                var templateDir = expandPath("/wheelscli/templates/model");
                expect(directoryExists(templateDir)).toBeTrue();
                
                expect(fileExists(templateDir & "/Model.cfc")).toBeTrue();
                expect(fileExists(templateDir & "/ModelWithValidation.cfc")).toBeTrue();
                expect(fileExists(templateDir & "/ModelWithAudit.cfc")).toBeTrue();
                expect(fileExists(templateDir & "/ModelComplete.cfc")).toBeTrue();
            });
            
            it("should have controller templates", function() {
                var templateDir = expandPath("/wheelscli/templates/controller");
                expect(directoryExists(templateDir)).toBeTrue();
                
                expect(fileExists(templateDir & "/Controller.cfc")).toBeTrue();
                expect(fileExists(templateDir & "/ResourceController.cfc")).toBeTrue();
            });
            
        });
    }
    
}