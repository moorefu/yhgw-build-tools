--
-- Licensed to the Apache Software Foundation (ASF) under one or more
-- contributor license agreements.  See the NOTICE file distributed with
-- this work for additional information regarding copyright ownership.
-- The ASF licenses this file to You under the Apache License, Version 2.0
-- (the "License"); you may not use this file except in compliance with
-- the License.  You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

package = "yhgw"
version = "master-0"
supported_platforms = {"linux", "macosx","mingw"}

source = {
    url = "git://gitlab.ylzpay.com:asc/cad/yhgwstack/yhgw.git",
    branch = "master",
}

description = {
    summary = "Apache APISIX(incubating) is a cloud-native microservices API gateway, delivering the ultimate performance, security, open source and scalable platform for all your APIs and microservices.",
    homepage = "https://gitlab.ylzpay.com/asc/cad/yhgwstack/yhgw",
    license = "Apache License 2.0",
}

dependencies = {
    "jmespath = 0.1.1-0",
    "api7-dkjson = 0.1.1",
    "lua-resty-crypto",
    "lua-resty-openssl",
    "lua-resty-mlcache = 2.4.1",
    "lua-resty-redis = 0.29-0",
    "lua-resty-requests",
    "api7-snowflake = 2.0-1",
    "lua-resty-redis-connector  = 0.11.0-0"
}

build = {
    type = "make",
    build_variables = {
        CFLAGS="$(CFLAGS)",
        LIBFLAG="$(LIBFLAG)",
        LUA_LIBDIR="$(LUA_LIBDIR)",
        LUA_BINDIR="$(LUA_BINDIR)",
        LUA_INCDIR="$(LUA_INCDIR)",
        LUA="$(LUA)",
    },
    install_variables = {
        INST_PREFIX="$(PREFIX)",
        INST_BINDIR="$(BINDIR)",
        INST_LIBDIR="$(LIBDIR)",
        INST_LUADIR="$(LUADIR)",
        INST_CONFDIR="$(CONFDIR)",
    },
}
