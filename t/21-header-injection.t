use Test::Nginx::Socket 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();

$ENV{TEST_NGINX_RESOLVER} = '8.8.8.8';
$ENV{TEST_COVERAGE} ||= 0;

our $HttpConfig = qq{
    lua_package_path "$pwd/lib/?.lua;/usr/local/share/lua/5.1/?.lua;;";
    error_log logs/error.log debug;

    init_by_lua_block {
        if $ENV{TEST_COVERAGE} == 1 then
            jit.off()
            require("luacov.runner").init()
        end
    }
};

no_long_string();

run_tests();

__DATA__

=== TEST 1: Rejects header injection in path
--- http_config eval: $::HttpConfig
--- config
    location = /a {
        content_by_lua '
            local http = require "resty.http"
            local httpc = http.new()
            httpc:connect{
                scheme = "http",
                host = "127.0.0.1",
                port = ngx.var.server_port
            }

            local res, err = httpc:request{
                method = "GET",
                path = "/b\\r\\nInjected: true"
            }

            if not res then
                ngx.say(err)
            else
                ngx.say("OK")
            end

            httpc:close()
        ';
    }
--- request
GET /a
--- response_body
invalid characters found in path
--- no_error_log
[error]



=== TEST 2: Rejects header injection in query
--- http_config eval: $::HttpConfig
--- config
    location = /a {
        content_by_lua '
            local http = require "resty.http"
            local httpc = http.new()
            httpc:connect{
                scheme = "http",
                host = "127.0.0.1",
                port = ngx.var.server_port
            }

            local res, err = httpc:request{
                method = "GET",
                path = "/b",
                query = "key=value\\r\\nInjected: true"
            }

            if not res then
                ngx.say(err)
            else
                ngx.say("OK")
            end

            httpc:close()
        ';
    }
--- request
GET /a
--- response_body
invalid characters found in query
--- no_error_log
[error]



=== TEST 3: Rejects header injection in header key
--- http_config eval: $::HttpConfig
--- config
    location = /a {
        content_by_lua '
            local http = require "resty.http"
            local httpc = http.new()
            httpc:connect{
                scheme = "http",
                host = "127.0.0.1",
                port = ngx.var.server_port
            }

            local res, err = httpc:request{
                method = "GET",
                path = "/b",
                headers = {
                    ["Test-Header\\r\\nInjected"] = "value"
                }
            }

            if not res then
                ngx.say(err)
            else
                ngx.say("OK")
            end

            httpc:close()
        ';
    }
--- request
GET /a
--- response_body
invalid characters found in header key
--- no_error_log
[error]



=== TEST 4: Rejects header injection in header value
--- http_config eval: $::HttpConfig
--- config
    location = /a {
        content_by_lua '
            local http = require "resty.http"
            local httpc = http.new()
            httpc:connect{
                scheme = "http",
                host = "127.0.0.1",
                port = ngx.var.server_port
            }

            local res, err = httpc:request{
                method = "GET",
                path = "/b",
                headers = {
                    ["Test-Header"] = "value\\r\\nInjected: true"
                }
            }

            if not res then
                ngx.say(err)
            else
                ngx.say("OK")
            end

            httpc:close()
        ';
    }
--- request
GET /a
--- response_body
invalid characters found in header value
--- no_error_log
[error]



=== TEST 5: Allows normal requests with valid spaces and tabs in headers
--- http_config eval: $::HttpConfig
--- config
    location = /a {
        content_by_lua '
            local http = require "resty.http"
            local httpc = http.new()
            httpc:connect{
                scheme = "http",
                host = "127.0.0.1",
                port = ngx.var.server_port
            }

            local res, err = httpc:request{
                method = "GET",
                path = "/b",
                headers = {
                    ["Test-Header"] = "value \\t something"
                }
            }

            if not res then
                ngx.say(err)
            else
                ngx.status = res.status
                ngx.say(res.headers["Test-Header"])
            end

            httpc:close()
        ';
    }
    location = /b {
        content_by_lua '
            ngx.header["Test-Header"] = ngx.req.get_headers()["Test-Header"]
            ngx.say("OK")
        ';
    }
--- request
GET /a
--- response_body
value 	 something
--- no_error_log
[error]
