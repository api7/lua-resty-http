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



=== TEST 6: Rejects spaces in path
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
                path = "/foo bar"
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



=== TEST 7: Rejects spaces in query literal
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
                query = "key=value with space"
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



=== TEST 8: Rejects invalid characters in header key
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
                    ["Test:Header"] = "value"
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



=== TEST 9: Allows non-English characters (UTF-8) in path
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
                path = "/path/你好"
            }

            if not res then
                ngx.say(err)
            else
                ngx.say("OK")
            end

            httpc:close()
        ';
    }
    location /path/ {
        echo "OK";
    }
--- request
GET /a
--- response_body
OK
--- no_error_log
[error]



=== TEST 10: Allows non-English characters (UTF-8) in query
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
                query = "key=你好"
            }

            if not res then
                ngx.say(err)
            else
                ngx.say("OK")
            end

            httpc:close()
        ';
    }
    location = /b {
        echo "OK";
    }
--- request
GET /a
--- response_body
OK
--- no_error_log
[error]



=== TEST 11: Allows non-English characters (UTF-8) in header value
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
                    ["X-Test"] = "你好"
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
    location = /b {
        echo "OK";
    }
--- request
GET /a
--- response_body
OK
--- no_error_log
[error]



=== TEST 12: Allows exotic but valid characters in path and query
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
                path = "/_a-Z~.!$&*+,;=:@",
                query = "k=_a-Z~.!$&*+,;=:@"
            }

            if not res then
                ngx.say(err)
            else
                ngx.say("OK")
            end

            httpc:close()
        ';
    }
    location /_a-Z {
        echo "OK";
    }
--- request
GET /a
--- response_body
OK
--- no_error_log
[error]

