# Verify Token Plugin
### Table Of Contents
- [ Overview ](#overview)
- [ Running tests ](#tests)
- [ Run Kong in docker container ](#kong_local)
- [ Installing the plugin with LuaRocks](#install_plugin)
- [ Distributing via luarocks](#distribution)
- [ Contributing ](#contributing)

<a name="overview"></a>
## Overview
The verify-token when enabled, will intercept each request made to a specific service or all services and verifies that the user session is still valid and a 401 it is not. It also provides a Kong admin endpoint to blacklist a specific session. This is useful when we want to invalidate a user's session when they logout.

On each request, the plugin will decode the JWT and perform a lookup on the `jti` against the `invalidated_token` database to see if the token as previously been invalidated. If it has, then it will respond to the request with a 401. The `${KONG_ADMIN_URL}/invalidate-token` admin endpoint will store the session in the blacklist database. Ideally, this endpoint should be invoked on logout.

Example payload
```json
{
  "session_id": "12345",
  "exp": 1564711934,
  "iat": 1564798334
}
```

<a name="tests"></a>
### Running tests
Prerequisites:

* Vagrant
    * `brew cask install vagrant`
* Virtualbox
    * `brew cask install virtualbox`

To run tests:

Follow the [development environment setup instructions](https://github.com/Kong/kong-vagrant#development-environment), specifically:
```
# Clone the development environment
git clone https://github.com/Kong/kong-vagrant
cd kong-vagrant

# Clone Kong and checkout the version we're using
git clone https://github.com/Kong/kong
cd kong
git checkout 1.3.0

# Clone the plugin
git clone https://github.com/localz/kong-plugin-verify-token

cd ..
```

Your folder structure should look like this:
```bash
kong-vagrant/
└── kong
├── kong-plugin # verify-token repository
└── ..
```

Now we can spin up vagrant and run tests:
```bash
# In the `kong-vagrant` folder
KONG_VERSION=1.3.0 vagrant up

# Once the above has finished running
vagrant ssh

# Build Kong
cd /kong
make dev

# Tell Kong about our plugin
export KONG_PLUGINS=bundled,verify-token

# Build the plugin
cd /kong/kong-plugin
make install
cd /kong

# Run initial migrations
bin/kong migrations up -c spec/kong_tests.conf

# Run this to run tests consistently
cd kong-plugin && make install && cd .. &&                         # Build the plugin
bin/kong migrations reset -y -c spec/kong_tests.conf &&            # Reset migrations/postgres
psql -d kong_tests -U postgres -c 'TRUNCATE TABLE consumers;' &&   # Consumers never seem to be wiped...
kong migrations up -c spec/kong_tests.conf &&                      # Run migrations
bin/busted -o gtest -v --exclude-tags=ci kong-plugin/spec/         # Run tests for our plugin
```

<a name="kong_local"></a>
### Run Kong in docker container

**Start the database migrations**

This will perform all the migrations necessary and initializes the database tables for the plugin

```bash
docker-compose up -d kong-database
docker-compose run kong kong migrations bootstrap
``` 

*Note that you might have to run it a few times as the command may fail if postgres/Kong does not start in time.*

**Start Kong**

When the migrations have completed, we can spin up Kong

```bash
docker-compose up
```

**Verify kong has started successfully**

```bash
curl localhost:8001
```

**Start a service**

We recommend you to run any of the Localz api and point the Kong service to it for testing. The easiest way to start the api is to utilize the `localz-to-local-platform` by cloning the repository and run the provided scripts to start a service 

```bash
./run SERVICE_NAME
```

**Add service to Kong**

we would need to add the service entry into the Kong Database and point it to the address of the API created in the previous step.

For example, point Kong to the User API that was created previously we can make the following request to Kong.
```bash
curl --request POST \
  --url http://localhost:8001/services \
  --header 'content-type: application/json' \
  --data '{
  "name": "user-api",
  "port": 3001,
  "protocol": "http",
  "host": "host.docker.internal",
  "path": "/user"
  }'
```
*Note: `host.docker.internal` maps to the `localhost` of the host machine*


**Add the route to Kong**

Add a route to the service which will tell Kong which methods to expose for the given service. 

To add a route for the service created above

```bash
curl --request POST \
  --url http://localhost:8001/routes/ \
  --header 'content-type: application/json' \
  --data '{
  "protocols": ["http", "https"],
  "methods": ["GET", "POST"],
  "hosts": ["localhost"],
  "paths": ["/"],
  "service": {
    "id": "4520eb5e-869c-4e56-a2d6-e5cd821b1d46"
  }
  }'
```

Test that is running correctly by sending a request to the user service.

```bash
curl localhost:8000/user/healthcheck
```

<a name="install_plugin"></a>
### Installing the plugin with LuaRocks
We would be using LuaRocks to package the contents of the plugin. The `rockspec` file contains information on what modules to package and the files associated with the modules. Each module needs to be explicitly specified in the `rockspec` for it be packaged by LuaRocks. 

For example, if we want to add the `daos.lua` module, we would need to add the following to the list of modules to build 

```lua
build = {
  modules = {
    -- ...other modules 
    ["kong.plugins.MODULE_NAME.daos"] = "/kong/plugins/MODULE_NAME/daos.lua"
  }
}
```

**Installing the plugin**

Package the plugin using Luarocks
```bash
# install it locally (based on the `.rockspec` in the current directory)
luarocks make

# pack the module
luarocks pack verify-token VERSION_NUMBER

# install it to the local luarocks modules directory located at
# ~/.luarocks/share/lua/LUA_VERSION/kong/plugins/PLUGIN_NAME
luarocks install --local verify-token-VERSION_NUMBER.all.rock
```

The local lua rocks module directory is mounted to the `/plugins` directory inside the docker container. The `/plugins` path is then specified in the `LUA_PATH` environement variable in the `docker-compose.yml` file which tells Kong where to find the custom plugins. 
Make sure not to change this to `KONG_LUA_PACKAGE_PATH` as doing so will cause the plugin database migration to not run.

**Enabling the plugin to Kong service/route**

Kong does not enable the plugin to all the routes by default. To do so, run the following command:
```bash
curl --request POST \
  --url http://localhost:8001/plugins/ \
  --header 'content-type: application/json' \
  --data '{
  "name": "verify-token",
  "enabled": true
  }'
```

<a name="distribution"></a>
### Distributing via luarocks
To push the plugin via luarocks:
```
# Make sure your changes are merged into master, and then cut a new release. 
# Make sure the rockspec tag and version match your git tag
git checkout 1.0.0 # 1.0.0 is your version number

luarocks upload verify-token-1.0.0-1.rockspec --api-key=KEY # You'll need to get an API key from luarocks
```

<a name="contributing"></a>
#### Contributing
Be sure to read the Kong Plugin Developement Documentation here:

https://docs.konghq.com/1.3.x/plugin-development/
