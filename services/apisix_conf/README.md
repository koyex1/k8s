#commands to setup api management via curl.
#so you create a consumer that is used to create jwt credentials
create consumer and consumers key and secret. admin api key authorizes the creation as a header.

#CORS
curl http://localhost:9180/apisix/admin/global_rules/1 \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -X PUT \
  -d '
{
  "plugins": {
    "cors": {
      "allow_origins": "*",
      "allow_methods": "*",
      "allow_headers": "*",
      "expose_headers": "*",
      "max_age": 3600,
      "allow_credential": false
    }
  }
}'

#create register route
curl http://localhost:9180/apisix/admin/routes/register-route \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -X PUT \
  -d '
{
  "uri": "/register",
  "methods": ["POST"],
  "upstream": {
    "type": "roundrobin",
    "nodes": {
      "register-service:8080": 1
    }
  }
}'

#create route (login service)
curl http://localhost:9180/apisix/admin/routes/login-route \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -X PUT \
  -d '
{
  "uri": "/login",
  "methods": ["POST"],
  "upstream": {
    "type": "roundrobin",
    "nodes": {
      "login-service:3000": 1
    }
  }
}'

#create consumer [login]
curl http://localhost:9180/apisix/admin/consumers \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -X PUT \
  -d '
{
  "username": "dev_app",
  "plugins": {
    "jwt-auth": {
      "key": "dev_app_key",
      "secret": "my-secret-key"
    }
  }
}'

#protect other services(jwt required)
curl http://localhost:9180/apisix/admin/routes/product-route \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -X PUT \
  -d '
{
  "uri": "/products*",
  "plugins": {
    "jwt-auth": {
      "store_in_ctx": true
    },
    "serverless-pre-function": {
      "phase": "access",
      "functions": [
        "return function(conf, ctx)\n
          local jwt = ctx.jwt_auth_payload\n

          if not jwt then\n
            ngx.log(ngx.ERR, \"JWT payload is NIL\")\n
            ngx.req.set_header(\"X-JWT-DEBUG\", \"nil\")\n
            return\n
          end\n

          ngx.req.set_header(\"X-Email\", jwt.email or \"missing\")\n
          ngx.req.set_header(\"X-User-Id\", tostring(jwt.user_id or \"missing\"))\n
          ngx.req.set_header(\"X-Username\", jwt.username or \"missing\")\n

        end"
      ]
    }
  },
  "upstream": {
    "type": "roundrobin",
    "nodes": {
      "products-service:8080": 1
    }
  }
}'

#protect other services(jwt required)
curl http://localhost:9180/apisix/admin/routes/cart-route \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -X PUT \
  -d '
{
  "uri": "/cart*",
  "plugins": {
    "jwt-auth": {
      "store_in_ctx": true
    },
    "serverless-pre-function": {
      "phase": "access",
      "functions": [
        "return function(conf, ctx)\n
          local jwt = ctx.jwt_auth_payload\n

          if not jwt then\n
            ngx.log(ngx.ERR, \"JWT payload is NIL\")\n
            ngx.req.set_header(\"X-JWT-DEBUG\", \"nil\")\n
            return\n
          end\n

          ngx.req.set_header(\"X-Email\", jwt.email or \"missing\")\n
          ngx.req.set_header(\"X-User-Id\", tostring(jwt.user_id or \"missing\"))\n
          ngx.req.set_header(\"X-Username\", jwt.username or \"missing\")\n

        end"
      ]
    }
  },
  "upstream": {
    "type": "roundrobin",
    "nodes": {
      "cart-service:8080": 1
    }
  }
}'

#protect other services(jwt required)
curl http://localhost:9180/apisix/admin/routes/order-route \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -X PUT \
  -d '
{
  "uri": "/order*",
  "plugins": {
    "jwt-auth": {
      "store_in_ctx": true
    },
    "serverless-pre-function": {
      "phase": "access",
      "functions": [
        "return function(conf, ctx)\n
          local jwt = ctx.jwt_auth_payload\n

          if not jwt then\n
            ngx.log(ngx.ERR, \"JWT payload is NIL\")\n
            ngx.req.set_header(\"X-JWT-DEBUG\", \"nil\")\n
            return\n
          end\n

          ngx.req.set_header(\"X-Email\", jwt.email or \"missing\")\n
          ngx.req.set_header(\"X-User-Id\", tostring(jwt.user_id or \"missing\"))\n
          ngx.req.set_header(\"X-Username\", jwt.username or \"missing\")\n

        end"
      ]
    }
  },
  "upstream": {
    "type": "roundrobin",
    "nodes": {
      "order-service:8000": 1
    }
  }
}'

#protect other services(jwt required)
curl http://localhost:9180/apisix/admin/routes/notification-route \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -X PUT \
  -d '
{
  "uri": "/notifications*",
  "plugins": {
    "jwt-auth": {
      "store_in_ctx": true
    },
    "serverless-pre-function": {
      "phase": "access",
      "functions": [
        "return function(conf, ctx)\n
          local jwt = ctx.jwt_auth_payload\n

          if not jwt then\n
            ngx.log(ngx.ERR, \"JWT payload is NIL\")\n
            ngx.req.set_header(\"X-JWT-DEBUG\", \"nil\")\n
            return\n
          end\n

          ngx.req.set_header(\"X-Email\", jwt.email or \"missing\")\n
          ngx.req.set_header(\"X-User-Id\", tostring(jwt.user_id or \"missing\"))\n
          ngx.req.set_header(\"X-Username\", jwt.username or \"missing\")\n

        end"
      ]
    }
  },
  "upstream": {
    "type": "roundrobin",
    "nodes": {
      "notification-service:3000": 1
    }
  }
}'

