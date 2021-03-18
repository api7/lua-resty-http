use Test::Nginx::Socket::Lua::Stream 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();

no_long_string();
#no_diff();

add_block_preprocessor(sub {
    my ($block) = @_;

    my $http_config = <<_EOC;
    server {
        listen *:8081 ssl;
        ssl_certificate ../../cert/mtls_client.crt;
        ssl_certificate_key ../../cert/mtls_client.key;
        ssl_verify_client on;
        ssl_client_certificate ../../cert/mtls_ca.crt;

        location / {
            content_by_lua_block {
            }
        }
    }
_EOC

    $block->set_value("http_config", $http_config);

    my $stream_config = <<_EOC;
    lua_package_path "$pwd/lib/?.lua;;";
_EOC

    $block->set_value("stream_config", $stream_config);

    $block;
});

run_tests();

__DATA__

=== TEST 1: sanity
--- stream_server_config
    content_by_lua_block {
        local http = require "resty.http"
        local httpc = http.new()

        local res, err = httpc:request_uri("https://127.0.0.1:8081", {
            ssl_verify = false,
            ssl_cert_path = "t/cert/mtls_client.crt",
            ssl_key_path = "t/cert/mtls_client.key",
        })
        if not res then
            ngx.log(ngx.ERR, err)
        else
            ngx.say(res.status)
        end
    }
--- stream_response
200
--- no_error_log
[error]



=== TEST 2: cert not found
--- stream_server_config
    content_by_lua_block {
        local http = require "resty.http"
        local httpc = http.new()

        local res, err = httpc:request_uri("https://127.0.0.1:8081", {
            ssl_verify = false,
            ssl_cert_path = "t/cert/test.crt",
            ssl_key_path = "../t/cert/test.key",
        })
        if not res then
            ngx.log(ngx.ERR, err)
        else
            ngx.say(res.status)
        end
    }
--- error_log
No such file or directory



=== TEST 3: key not found
--- stream_server_config
    content_by_lua_block {
        local http = require "resty.http"
        local httpc = http.new()

        local res, err = httpc:request_uri("https://127.0.0.1:8081", {
            ssl_verify = false,
            ssl_cert_path = "../t/cert/test.crt",
            ssl_key_path = "t/cert/test.key",
        })
        if not res then
            ngx.log(ngx.ERR, err)
        else
            ngx.say(res.status)
        end
    }
--- error_log
No such file or directory



=== TEST 4: untrusted cert
--- stream_server_config
    content_by_lua_block {
        local http = require "resty.http"
        local httpc = http.new()

        local res, err = httpc:request_uri("https://127.0.0.1:8081", {
            ssl_verify = false,
            ssl_cert_path = "t/cert/wrong.crt",
            ssl_key_path = "t/cert/wrong.key",
        })
        if not res then
            ngx.log(ngx.ERR, err)
        else
            ngx.say(res.status)
        end
    }
--- stream_response
400
--- no_error_log
[error]



=== TEST 5: mismatched cert & key
--- stream_server_config
    content_by_lua_block {
        local http = require "resty.http"
        local httpc = http.new()

        local res, err = httpc:request_uri("https://127.0.0.1:8081", {
            ssl_verify = false,
            ssl_cert_path = "t/cert/wrong.crt",
            ssl_key_path = "t/cert/mtls_client.key",
        })
        if not res then
            ngx.log(ngx.ERR, err)
        else
            ngx.say(res.status)
        end
    }
--- error_log
set client private key failed



=== TEST 6: no cert
--- stream_server_config
    content_by_lua_block {
        local http = require "resty.http"
        local httpc = http.new()

        local res, err = httpc:request_uri("https://127.0.0.1:8081", {
            ssl_verify = false,
        })
        if not res then
            ngx.log(ngx.ERR, err)
        else
            ngx.say(res.status)
        end
    }
--- stream_response
400
--- no_error_log
[error]



=== TEST 7: verify
--- stream_server_config
    lua_ssl_trusted_certificate ../../cert/mtls_ca.crt;
    content_by_lua_block {
        local http = require "resty.http"
        local httpc = http.new()

        local res, err = httpc:request_uri("https://127.0.0.1:8081", {
            ssl_verify = true,
            ssl_cert_path = "t/cert/mtls_client.crt",
            ssl_key_path = "t/cert/mtls_client.key",
        })
        if not res then
            ngx.log(ngx.ERR, err)
        else
            ngx.say(res.status)
        end
    }
--- stream_response
200
--- no_error_log
[error]



=== TEST 8: SNI
--- stream_server_config
    lua_ssl_trusted_certificate ../../cert/mtls_ca.crt;
    content_by_lua_block {
        local http = require "resty.http"
        local httpc = http.new()

        local res, err = httpc:request_uri("https://127.0.0.1:8081", {
            ssl_server_name = "aaa.com",
            ssl_verify = true,
            ssl_cert_path = "t/cert/mtls_client.crt",
            ssl_key_path = "t/cert/mtls_client.key",
        })
        if not res then
            ngx.log(ngx.ERR, err)
        else
            ngx.say(res.status)
        end
    }
--- error_log
certificate host mismatch
