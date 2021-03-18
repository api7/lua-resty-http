use Test::Nginx::Socket 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();

no_long_string();
#no_diff();

add_block_preprocessor(sub {
    my ($block) = @_;

    my $http_config = <<_EOC;
    lua_package_path "$pwd/lib/?.lua;;";
    server {
        listen *:8081 ssl;
        ssl_certificate ../../cert/test.crt;
        ssl_certificate_key ../../cert/test.key;
        ssl_verify_client on;
        ssl_client_certificate ../../cert/mtls_ca.crt;

        location / {
            content_by_lua_block {
            }
        }
    }
_EOC

    $block->set_value("http_config", $http_config);

    $block;
});

run_tests();

__DATA__

=== TEST 1: sanity
--- config
    location /lua {
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
                ngx.exit(res.status)
            end
        }
    }
--- request
GET /lua
--- no_error_log
[error]



=== TEST 2: cert not found
--- config
    location /lua {
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
                ngx.exit(res.status)
            end
        }
    }
--- request
GET /lua
--- error_log
No such file or directory



=== TEST 3: key not found
--- config
    location /lua {
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
                ngx.exit(res.status)
            end
        }
    }
--- request
GET /lua
--- error_log
No such file or directory



=== TEST 4: untrusted cert
--- config
    location /lua {
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
                ngx.exit(res.status)
            end
        }
    }
--- request
GET /lua
--- error_code: 400
--- no_error_log
[error]



=== TEST 5: mismatched cert & key
--- config
    location /lua {
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
                ngx.exit(res.status)
            end
        }
    }
--- request
GET /lua
--- error_log
set client private key failed



=== TEST 6: no cert
--- config
    location /lua {
        content_by_lua_block {
            local http = require "resty.http"
            local httpc = http.new()

            local res, err = httpc:request_uri("https://127.0.0.1:8081", {
                ssl_verify = false,
            })
            if not res then
                ngx.log(ngx.ERR, err)
            else
                ngx.exit(res.status)
            end
        }
    }
--- request
GET /lua
--- error_code: 400
--- no_error_log
[error]
