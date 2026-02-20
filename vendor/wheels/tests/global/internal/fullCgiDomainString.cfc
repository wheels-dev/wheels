component extends="wheels.tests.Test" {

    function setup(){
    }
    function teardown(){
    }
    function Test_$fullDomainString(){
        r = $fullDomainString("http://www.cfwheels.com");
        r2 = $fullDomainString("https://www.cfwheels.com");
        r3 = $fullDomainString("http://www.cfwheels.com:8080");
        r4 = $fullDomainString("https://www.cfwheels.com:8443");
        r5 = $fullDomainString("www.cfwheels.com");
        r6 = $fullDomainString("www.cfwheels.com:80");
        r7 = $fullDomainString("www.cfwheels.com:8888");
        r8 = $fullDomainString("www.cfwheels.com:443");
        assert("r EQ 'http://www.cfwheels.com:80'");
        assert("r2 EQ 'https://www.cfwheels.com:443'");
        assert("r3 EQ 'http://www.cfwheels.com:8080'");
        assert("r4 EQ 'https://www.cfwheels.com:8443'");
        assert("r5 EQ 'http://www.cfwheels.com:80'");
        assert("r6 EQ 'http://www.cfwheels.com:80'");
        assert("r7 EQ 'http://www.cfwheels.com:8888'");
        assert("r8 EQ 'https://www.cfwheels.com:443'");
    }
    function Test_get_Full_Domain_String_From_CGI_https_non_standard(){
        r = $fullCgiDomainString(
        {
            server_name = "www.cfwheels.com",
            server_port = 8443,
            server_port_secure = 1
        });
        assert("r EQ 'https://www.cfwheels.com:8443'");
    }
    function Test_get_Full_Domain_String_From_CGI_https(){
        r = $fullCgiDomainString(
        {
            server_name = "www.cfwheels.com",
            server_port = 443,
            server_port_secure = 1
        });
        assert("r EQ 'https://www.cfwheels.com:443'");
    }
    function Test_get_Full_Domain_String_From_CGI_http(){
        r = $fullCgiDomainString(
        {
            server_name = "www.cfwheels.com",
            server_port = 80,
            server_port_secure = 0
        });
        assert("r EQ 'http://www.cfwheels.com:80'");
    }
    function Test_get_Full_Domain_String_From_CGI_http_non_standard(){
        r = $fullCgiDomainString(
        {
            server_name = "www.cfwheels.com",
            server_port = 8080,
            server_port_secure = 0
        });
        assert("r EQ 'http://www.cfwheels.com:8080'");
    }
}
