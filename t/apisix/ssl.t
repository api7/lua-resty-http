use Test::Nginx::Socket 'no_plan';
use Cwd qw(cwd);

my $pwd = cwd();

no_long_string();

add_block_preprocessor(sub {
    my ($block) = @_;

    my $http_config = <<_EOC;
    lua_package_path "$pwd/lib/?.lua;;";

    server {
        listen *:8081 ssl;
        ssl_certificate ../../cert/mtls_server.crt;
        ssl_certificate_key ../../cert/mtls_server.key;
        ssl_verify_client on;
        ssl_client_certificate ../../cert/mtls_ca.crt;

        location / {
            content_by_lua_block {
            }
        }
    }
_EOC

    $block->set_value("http_config", $http_config);
});

run_tests();

__DATA__

=== TEST 1: sanity cert and key from path
--- config
    location /lua {
        lua_ssl_verify_depth 2;
        lua_ssl_trusted_certificate ../../../t/cert/mtls_ca.crt;
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
                ngx.exit(res.status)
            end
        }
    }
--- request
GET /lua
--- no_error_log
[error]



=== TEST 2: sanity cert and key from content
--- config
    location /lua {
        lua_ssl_verify_depth 2;
        lua_ssl_trusted_certificate ../../../t/cert/mtls_ca.crt;
        content_by_lua_block {
            local http = require "resty.http"
            local httpc = http.new()

            local res, err = httpc:request_uri("https://127.0.0.1:8081", {
                ssl_verify = true,
                ssl_cert = [[-----BEGIN CERTIFICATE-----
MIIDUzCCAjugAwIBAgIURw+Rc5FSNUQWdJD+quORtr9KaE8wDQYJKoZIhvcNAQEN
BQAwWDELMAkGA1UEBhMCY24xEjAQBgNVBAgMCUd1YW5nRG9uZzEPMA0GA1UEBwwG
Wmh1SGFpMRYwFAYDVQQDDA1jYS5hcGlzaXguZGV2MQwwCgYDVQQLDANvcHMwHhcN
MjIxMjAxMTAxOTU3WhcNNDIwODE4MTAxOTU3WjBOMQswCQYDVQQGEwJjbjESMBAG
A1UECAwJR3VhbmdEb25nMQ8wDQYDVQQHDAZaaHVIYWkxGjAYBgNVBAMMEWNsaWVu
dC5hcGlzaXguZGV2MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzypq
krsJ8MaqpS0kr2SboE9aRKOJzd6mY3AZLq3tFpio5cK5oIHkQLfeaaLcd4ycFcZw
FTpxc+Eth6I0X9on+j4tEibc5IpDnRSAQlzHZzlrOG6WxcOza4VmfcrKqj27oodr
oqXv05r/5yIoRrEN9ZXfA8n2OnjhkP+C3Q68L6dBtPpv+e6HaAuw8MvcsEo+MQwu
cTZyWqWT2UzKVzToW29dHRW+yZGuYNWRh15X09VSvx+E0s+uYKzN0Cyef2C6VtBJ
KmJ3NtypAiPqw7Ebfov2Ym/zzU9pyWPi3P1mYPMKQqUT/FpZSXm4iSy0a5qTYhkF
rFdV1YuYYZL5YGl9aQIDAQABox8wHTAbBgNVHREEFDASghBhZG1pbi5hcGlzaXgu
ZGV2MA0GCSqGSIb3DQEBDQUAA4IBAQBepRpwWdckZ6QdL5EuufYwU7p5SIqkVL/+
N4/l5YSjPoAZf/M6XkZu/PsLI9/kPZN/PX4oxjZSDH14dU9ON3JjxtSrebizcT8V
aQ13TeW9KSv/i5oT6qBmj+V+RF2YCUhyzXdYokOfsSVtSlA1qMdm+cv0vkjYcImV
l3L9nVHRPq15dY9sbmWEtFBWvOzqNSuQYax+iYG+XEuL9SPaYlwKRC6eS/dbXa1T
PPWDQad2X/WmhxPzEHvjSl2bsZF1u0GEdKyhXWMOLCLiYIJo15G7bMz8cTUvkDN3
6WaWBd6bd2g13Ho/OOceARpkR/ND8PU78Y8cq+zHoOSqH+1aly5H
-----END CERTIFICATE-----]],
                ssl_key = [[-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAzypqkrsJ8MaqpS0kr2SboE9aRKOJzd6mY3AZLq3tFpio5cK5
oIHkQLfeaaLcd4ycFcZwFTpxc+Eth6I0X9on+j4tEibc5IpDnRSAQlzHZzlrOG6W
xcOza4VmfcrKqj27oodroqXv05r/5yIoRrEN9ZXfA8n2OnjhkP+C3Q68L6dBtPpv
+e6HaAuw8MvcsEo+MQwucTZyWqWT2UzKVzToW29dHRW+yZGuYNWRh15X09VSvx+E
0s+uYKzN0Cyef2C6VtBJKmJ3NtypAiPqw7Ebfov2Ym/zzU9pyWPi3P1mYPMKQqUT
/FpZSXm4iSy0a5qTYhkFrFdV1YuYYZL5YGl9aQIDAQABAoIBAD7tUG//lnZnsj/4
JXONaORaFj5ROrOpFPuRemS+egzqFCuuaXpC2lV6RHnr+XHq6SKII1WfagTb+lt/
vs760jfmGQSxf1mAUidtqcP+sKc/Pr1mgi/SUTawz8AYEFWD6PHmlqBSLTYml+La
ckd+0pGtk49wEnYSb9n+cv640hra9AYpm9LXUFaypiFEu+xJhtyKKWkmiVGrt/X9
3aG6MuYeZplW8Xq1L6jcHsieTOB3T+UBfG3O0bELBgTVexOQYI9O4Ejl9/n5/8WP
AbIw7PaAYc7fBkwOGh7/qYUdHnrm5o9MiRT6dPxrVSf0PZVACmA+JoNjCPv0Typf
3MMkHoECgYEA9+3LYzdP8j9iv1fP5hn5K6XZAobCD1mnzv3my0KmoSMC26XuS71f
vyBhjL7zMxGEComvVTF9SaNMfMYTU4CwOJQxLAuT69PEzW6oVEeBoscE5hwhjj6o
/lr5jMbt807J9HnldSpwllfj7JeiTuqRcCu/cwqKQQ1aB3YBZ7h5pZkCgYEA1ejo
KrR1hN2FMhp4pj0nZ5+Ry2lyIVbN4kIcoteaPhyQ0AQ0zNoi27EBRnleRwVDYECi
XAFrgJU+laKsg1iPjvinHibrB9G2p1uv3BEh6lPl9wPFlENTOjPkqjR6eVVZGP8e
VzxYxIo2x/QLDUeOpxySdG4pdhEHGfvmdGmr2FECgYBeknedzhCR4HnjcTSdmlTA
wI+p9gt6XYG0ZIewCymSl89UR9RBUeh++HQdgw0z8r+CYYjfH3SiLUdU5R2kIZeW
zXiAS55OO8Z7cnWFSI17sRz+RcbLAr3l4IAGoi9MO0awGftcGSc/QiFwM1s3bSSz
PAzYbjHUpKot5Gae0PCeKQKBgQCHfkfRBQ2LY2WDHxFc+0+Ca6jF17zbMUioEIhi
/X5N6XowyPlI6MM7tRrBsQ7unX7X8Rjmfl/ByschsTDk4avNO+NfTfeBtGymBYWX
N6Lr8sivdkwoZZzKOSSWSzdos48ELlThnO/9Ti706Lg3aSQK5iY+aakJiC+fXdfT
1TtsgQKBgQDRYvtK/Cpaq0W6wO3I4R75lHGa7zjEr4HA0Kk/FlwS0YveuTh5xqBj
wQz2YyuQQfJfJs7kbWOITBT3vuBJ8F+pktL2Xq5p7/ooIXOGS8Ib4/JAS1C/wb+t
uJHGva12bZ4uizxdL2Q0/n9ziYTiMc/MMh/56o4Je8RMdOMT5lTsRQ==
-----END RSA PRIVATE KEY-----]],
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



=== TEST 3: set cert from path and set key from content
--- config
    location /lua {
        lua_ssl_verify_depth 2;
        lua_ssl_trusted_certificate ../../../t/cert/mtls_ca.crt;
        content_by_lua_block {
            local http = require "resty.http"
            local httpc = http.new()

            local res, err = httpc:request_uri("https://127.0.0.1:8081", {
                ssl_verify = true,
                ssl_cert_path = "t/cert/mtls_client.crt",
                ssl_key = [[-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAzypqkrsJ8MaqpS0kr2SboE9aRKOJzd6mY3AZLq3tFpio5cK5
oIHkQLfeaaLcd4ycFcZwFTpxc+Eth6I0X9on+j4tEibc5IpDnRSAQlzHZzlrOG6W
xcOza4VmfcrKqj27oodroqXv05r/5yIoRrEN9ZXfA8n2OnjhkP+C3Q68L6dBtPpv
+e6HaAuw8MvcsEo+MQwucTZyWqWT2UzKVzToW29dHRW+yZGuYNWRh15X09VSvx+E
0s+uYKzN0Cyef2C6VtBJKmJ3NtypAiPqw7Ebfov2Ym/zzU9pyWPi3P1mYPMKQqUT
/FpZSXm4iSy0a5qTYhkFrFdV1YuYYZL5YGl9aQIDAQABAoIBAD7tUG//lnZnsj/4
JXONaORaFj5ROrOpFPuRemS+egzqFCuuaXpC2lV6RHnr+XHq6SKII1WfagTb+lt/
vs760jfmGQSxf1mAUidtqcP+sKc/Pr1mgi/SUTawz8AYEFWD6PHmlqBSLTYml+La
ckd+0pGtk49wEnYSb9n+cv640hra9AYpm9LXUFaypiFEu+xJhtyKKWkmiVGrt/X9
3aG6MuYeZplW8Xq1L6jcHsieTOB3T+UBfG3O0bELBgTVexOQYI9O4Ejl9/n5/8WP
AbIw7PaAYc7fBkwOGh7/qYUdHnrm5o9MiRT6dPxrVSf0PZVACmA+JoNjCPv0Typf
3MMkHoECgYEA9+3LYzdP8j9iv1fP5hn5K6XZAobCD1mnzv3my0KmoSMC26XuS71f
vyBhjL7zMxGEComvVTF9SaNMfMYTU4CwOJQxLAuT69PEzW6oVEeBoscE5hwhjj6o
/lr5jMbt807J9HnldSpwllfj7JeiTuqRcCu/cwqKQQ1aB3YBZ7h5pZkCgYEA1ejo
KrR1hN2FMhp4pj0nZ5+Ry2lyIVbN4kIcoteaPhyQ0AQ0zNoi27EBRnleRwVDYECi
XAFrgJU+laKsg1iPjvinHibrB9G2p1uv3BEh6lPl9wPFlENTOjPkqjR6eVVZGP8e
VzxYxIo2x/QLDUeOpxySdG4pdhEHGfvmdGmr2FECgYBeknedzhCR4HnjcTSdmlTA
wI+p9gt6XYG0ZIewCymSl89UR9RBUeh++HQdgw0z8r+CYYjfH3SiLUdU5R2kIZeW
zXiAS55OO8Z7cnWFSI17sRz+RcbLAr3l4IAGoi9MO0awGftcGSc/QiFwM1s3bSSz
PAzYbjHUpKot5Gae0PCeKQKBgQCHfkfRBQ2LY2WDHxFc+0+Ca6jF17zbMUioEIhi
/X5N6XowyPlI6MM7tRrBsQ7unX7X8Rjmfl/ByschsTDk4avNO+NfTfeBtGymBYWX
N6Lr8sivdkwoZZzKOSSWSzdos48ELlThnO/9Ti706Lg3aSQK5iY+aakJiC+fXdfT
1TtsgQKBgQDRYvtK/Cpaq0W6wO3I4R75lHGa7zjEr4HA0Kk/FlwS0YveuTh5xqBj
wQz2YyuQQfJfJs7kbWOITBT3vuBJ8F+pktL2Xq5p7/ooIXOGS8Ib4/JAS1C/wb+t
uJHGva12bZ4uizxdL2Q0/n9ziYTiMc/MMh/56o4Je8RMdOMT5lTsRQ==
-----END RSA PRIVATE KEY-----]],
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



=== TEST 4: sanity cert and key from content
--- config
    location /lua {
        lua_ssl_verify_depth 2;
        lua_ssl_trusted_certificate ../../../t/cert/mtls_ca.crt;
        content_by_lua_block {
            local http = require "resty.http"
            local httpc = http.new()

            local res, err = httpc:request_uri("https://127.0.0.1:8081", {
                ssl_verify = true,
                ssl_cert = [[-----BEGIN CERTIFICATE-----
MIIDUzCCAjugAwIBAgIURw+Rc5FSNUQWdJD+quORtr9KaE8wDQYJKoZIhvcNAQEN
BQAwWDELMAkGA1UEBhMCY24xEjAQBgNVBAgMCUd1YW5nRG9uZzEPMA0GA1UEBwwG
Wmh1SGFpMRYwFAYDVQQDDA1jYS5hcGlzaXguZGV2MQwwCgYDVQQLDANvcHMwHhcN
MjIxMjAxMTAxOTU3WhcNNDIwODE4MTAxOTU3WjBOMQswCQYDVQQGEwJjbjESMBAG
A1UECAwJR3VhbmdEb25nMQ8wDQYDVQQHDAZaaHVIYWkxGjAYBgNVBAMMEWNsaWVu
dC5hcGlzaXguZGV2MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAzypq
krsJ8MaqpS0kr2SboE9aRKOJzd6mY3AZLq3tFpio5cK5oIHkQLfeaaLcd4ycFcZw
FTpxc+Eth6I0X9on+j4tEibc5IpDnRSAQlzHZzlrOG6WxcOza4VmfcrKqj27oodr
oqXv05r/5yIoRrEN9ZXfA8n2OnjhkP+C3Q68L6dBtPpv+e6HaAuw8MvcsEo+MQwu
cTZyWqWT2UzKVzToW29dHRW+yZGuYNWRh15X09VSvx+E0s+uYKzN0Cyef2C6VtBJ
KmJ3NtypAiPqw7Ebfov2Ym/zzU9pyWPi3P1mYPMKQqUT/FpZSXm4iSy0a5qTYhkF
rFdV1YuYYZL5YGl9aQIDAQABox8wHTAbBgNVHREEFDASghBhZG1pbi5hcGlzaXgu
ZGV2MA0GCSqGSIb3DQEBDQUAA4IBAQBepRpwWdckZ6QdL5EuufYwU7p5SIqkVL/+
N4/l5YSjPoAZf/M6XkZu/PsLI9/kPZN/PX4oxjZSDH14dU9ON3JjxtSrebizcT8V
aQ13TeW9KSv/i5oT6qBmj+V+RF2YCUhyzXdYokOfsSVtSlA1qMdm+cv0vkjYcImV
l3L9nVHRPq15dY9sbmWEtFBWvOzqNSuQYax+iYG+XEuL9SPaYlwKRC6eS/dbXa1T
PPWDQad2X/WmhxPzEHvjSl2bsZF1u0GEdKyhXWMOLCLiYIJo15G7bMz8cTUvkDN3
6WaWBd6bd2g13Ho/OOceARpkR/ND8PU78Y8cq+zHoOSqH+1aly5H
-----END CERTIFICATE-----]],
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



=== TEST 5: ssl_cert and ssl_cert_path are both set
--- config
    location /lua {
        lua_ssl_verify_depth 2;
        lua_ssl_trusted_certificate ../../../t/cert/mtls_ca.crt;
        content_by_lua_block {
            local http = require "resty.http"
            local httpc = http.new()

            local res, err = httpc:request_uri("https://127.0.0.1:8081", {
                ssl_verify = true,
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
missing 'ssl_cert_path' or 'ssl_cert' when 'ssl_key_path' or 'ssl_key' is given



=== TEST 6: sanity cert and key from content
--- config
    location /lua {
        lua_ssl_verify_depth 2;
        lua_ssl_trusted_certificate ../../../t/cert/mtls_ca.crt;
        content_by_lua_block {
            local http = require "resty.http"
            local httpc = http.new()

            local res, err = httpc:request_uri("https://127.0.0.1:8081", {
                ssl_verify = true,
                ssl_cert = [[-----BEGIN CERTIFICATE-----
MIIDOjCCAiICAwD6zzANBgkqhkiG9w0BAQsFADBnMQswCQYDVQQGEwJjbjESMBAG
A1UECAwJR3VhbmdEb25nMQ8wDQYDVQQHDAZaaHVIYWkxDTALBgNVBAoMBGFwaTcx
DDAKBgNVBAsMA29wczEWMBQGA1UEAwwNY2EuYXBpc2l4LmRldjAeFw0yMDA2MjAx
MzE1MDBaFw0zMDA3MDgxMzE1MDBaMF0xCzAJBgNVBAYTAmNuMRIwEAYDVQQIDAlH
dWFuZ0RvbmcxDTALBgNVBAoMBGFwaTcxDzANBgNVBAcMBlpodUhhaTEaMBgGA1UE
AwwRY2xpZW50LmFwaXNpeC5kZXYwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQCfKI8uiEH/ifZikSnRa3/E2B4ohVWRwjo/IxyDEWomgR4tLk1pSJhP/4SC
LWuMQTFWTbSqt1IFYy4ZbVSHHyGoNPmJGrHRJCGE+sgpfzn0GjV4lXQPJD0k6GR1
CX2Mo1TWdFqSJ/Hc5AQwcQFnPfoLAwsBy4yqrlmf96ZAUytl/7Zkjf4P7mJkJHtM
/WgSR0pGhjZTAGRf5DJWoO51ki3i3JI+15mOhmnnCpnksnGVPfl92q92Hz/4v3iq
E+UThPYRpcGbnddzMvPaCXiavg8B/u2LVbn4l0adamqQGepOAjD/1xraOVP2W22W
0PztDXJ4rLe+capNS4oGuSUfkIENAgMBAAEwDQYJKoZIhvcNAQELBQADggEBAHKn
HxUhuk/nL2Sg5UB84OoJe5XPgNBvVMKN0c/NAPKVIPninvUcG/mHeKexPzE0sMga
RNos75N2199EXydqUcsJ8jL0cNtQ2k5JQXXg0ntNC4tuCgIKAOnO879y5hSG36e5
7wmAoVKnabgjej09zG1kkXvAmpgqoxeVCu7h7fK+AurLbsGCTaHoA5pG1tcHDxJQ
fpVcbBfwQDSBW3SQjiRqX453/01nw6kbOeLKYraJysaG8ZU2K8+WpW6JDubciHjw
fQnpU2U16XKivhxeuKYrV/INL0sxj/fZraNYErvJWzh5llvIdNLmeSPmvb50JUIs
+lDqn1MobTXzDpuCFXA=
-----END CERTIFICATE-----]],
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
private key failed
