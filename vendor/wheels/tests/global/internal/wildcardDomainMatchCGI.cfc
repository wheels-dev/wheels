component extends="wheels.tests.Test" {
    function setup(){
    }
    function teardown(){
    }
    function Test_simple_exact_match_http(){
        r = $wildcardDomainMatchCGI("http://www.domain.com",
        {
            server_name = "www.domain.com",
            server_port = 80,
            server_port_secure = 0
        });
        assert("r EQ true");
    }
    function Test_simple_exact_match_http_non_standard_port(){
        r = $wildcardDomainMatchCGI("http://www.domain.com:8080",
        {
            server_name = "www.domain.com",
            server_port = 8080,
            server_port_secure = 0
        });
        assert("r EQ true");
    }
    function Test_simple_exact_match_https(){
        r = $wildcardDomainMatchCGI("https://www.domain.com",
        {
            server_name = "www.domain.com",
            server_port = 443,
            server_port_secure = 1
        });
        assert("r EQ true");
    }
    function Test_simple_exact_match_https_non_standard_port(){
        r = $wildcardDomainMatchCGI("https://www.domain.com:8443",
        {
            server_name = "www.domain.com",
            server_port = 8443,
            server_port_secure = 1
        });
        assert("r EQ true");
    }
    function Test_simple_wildcard(){
        r = $wildcardDomainMatchCGI("https://*.domain.com",
        {
            server_name = "anything.domain.com",
            server_port = 443,
            server_port_secure = 1
        });
        assert("r EQ true");
    }
    function Test_simple_wildcard_suffix(){
        r = $wildcardDomainMatchCGI("https://www.domain.*",
        {
            server_name = "www.domain.net",
            server_port = 443,
            server_port_secure = 1
        });
        assert("r EQ true");
    }
    function Test_simple_wildcard_position(){
        r = $wildcardDomainMatchCGI("https://api.*.domain.com",
        {
            server_name = "api.staging.domain.com",
            server_port = 443,
            server_port_secure = 1
        });
        assert("r EQ true");
    }
}
