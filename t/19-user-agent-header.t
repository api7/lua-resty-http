use Test::Nginx::Socket 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();

$ENV{TEST_COVERAGE} ||= 0;

our $HttpConfig = qq{
lua_package_path "$pwd/lib/?.lua;;";

init_by_lua_block {
    if $ENV{TEST_COVERAGE} == 1 then
        jit.off()
        require("luacov.runner").init()
    end
}

underscores_in_headers On;
};

no_long_string();
no_diff();

run_tests();

__DATA__

=== TEST 1: set user-agent with http header
--- http_config eval: $::HttpConfig
--- config
location = /a {
    content_by_lua_block {
        local httpc = require("resty.http").new()
        assert(httpc:connect("127.0.0.1", ngx.var.server_port),
            "connect should return positively")

        local res, err = httpc:request{
            path = "/b",
            headers = {
                ["X_Foo"] = "bar",
                ["User-Agent"] = "test_user_agent",
            },
            use_default_user_agent = false
        }

        ngx.status = res.status
        ngx.print(res:read_body())

        httpc:close()
    }
}
location = /b {
    content_by_lua_block {
        ngx.say(ngx.req.get_headers()["User-Agent"])
        ngx.say(ngx.req.get_headers(nil, true)["X_Foo"])
    }
}
--- request
GET /a
--- response_body
test_user_agent
bar
--- no_error_log
[error]



=== TEST 2: set user-agent with http header and set use_default_user_agent with true
--- http_config eval: $::HttpConfig
--- config
location = /a {
    content_by_lua_block {
        local httpc = require("resty.http").new()
        assert(httpc:connect("127.0.0.1", ngx.var.server_port),
            "connect should return positively")

        local res, err = httpc:request{
            path = "/b",
            headers = {
                ["X_Foo"] = "bar",
                ["User-Agent"] = "test_user_agent",
            },
            use_default_user_agent = true
        }

        ngx.status = res.status
        ngx.print(res:read_body())

        httpc:close()
    }
}
location = /b {
    content_by_lua_block {
        ngx.say(ngx.req.get_headers()["User-Agent"])
        ngx.say(ngx.req.get_headers(nil, true)["X_Foo"])
    }
}
--- request
GET /a
--- response_body
test_user_agent
bar
--- no_error_log
[error]



=== TEST 3: set emtpy user-agent with http header and set use_default_user_agent with false
--- http_config eval: $::HttpConfig
--- config
location = /a {
    content_by_lua_block {
        local httpc = require("resty.http").new()
        assert(httpc:connect("127.0.0.1", ngx.var.server_port),
            "connect should return positively")

        local res, err = httpc:request{
            path = "/b",
            headers = {
                ["X_Foo"] = "bar",
            },
            use_default_user_agent = false
        }

        ngx.status = res.status
        ngx.print(res:read_body())

        httpc:close()
    }
}
location = /b {
    content_by_lua_block {
        ngx.say(ngx.req.get_headers()["User-Agent"])
        ngx.say(ngx.req.get_headers(nil, true)["X_Foo"])
    }
}
--- request
GET /a
--- response_body
nil
bar
--- no_error_log
[error]



=== TEST 4: set emtpy user-agent with http header and set use_default_user_agent with true
--- http_config eval: $::HttpConfig
--- config
location = /a {
    content_by_lua_block {
        local httpc = require("resty.http").new()
        assert(httpc:connect("127.0.0.1", ngx.var.server_port),
            "connect should return positively")

        local res, err = httpc:request{
            path = "/b",
            headers = {
                ["X_Foo"] = "bar",
            },
            use_default_user_agent = true
        }

        ngx.status = res.status
        ngx.print(res:read_body())

        httpc:close()
    }
}
location = /b {
    content_by_lua_block {
        ngx.say(ngx.req.get_headers()["User-Agent"])
        ngx.say(ngx.req.get_headers(nil, true)["X_Foo"])
    }
}
--- request
GET /a
--- response_body_like
lua-resty-http.*
bar
--- no_error_log
[error]
