/**
 * Create RESTful API controller and supporting files
 * 
 * {code:bash}
 * wheels generate api-resource users
 * wheels generate api-resource posts --model=true --docs=true
 * {code}
 */
component extends="../base" {

    /**
     * @name Name of the API resource (singular or plural)
     * @model Generate associated model
     * @docs Generate API documentation template
     * @auth Include authentication checks
     */
    function run(
        required string name, 
        boolean model=false,
        boolean docs=false,
        boolean auth=false
    ) {
        // Welcome message
        print.line();
        print.boldMagentaLine("Wheels API Resource Generator");
        print.line();
        
        print.line();
        print.boldGreenLine("This feature is currently under development");
        print.line();
    }
}