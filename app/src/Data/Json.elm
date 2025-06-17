-- ---------------------------------------------------------------------
--
-- Copyright (c) 2025 TI Tokyo    All Rights Reserved.
--
-- This file is provided to you under the Apache License,
-- Version 2.0 (the "License"); you may not use this file
-- except in compliance with the License.  You may obtain
-- a copy of the License at
--
--   http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing,
-- software distributed under the License is distributed on an
-- "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
-- KIND, either express or implied.  See the License for the
-- specific language governing permissions and limitations
-- under the License.
--
-- ---------------------------------------------------------------------

module Data.Json exposing
    ( decodeUserList
    , decodeServerInfo
    )

import Data.User exposing (..)
import Data.Server exposing (..)
import Util

import Json.Decode as D exposing (succeed, list, string, int, bool, map, map2, dict, oneOf, nullable, maybe, lazy, field)
import Json.Decode.Pipeline exposing (required, optional, hardcoded)
import Json.Encode
import Iso8601
import Time
import Dict

decodeServerInfo =
    succeed ServerInfo
        |> required "riak_version" string
        |> required "system_version" string
        |> required "uptime" string


decodeUserList : D.Decoder (List User)
decodeUserList =
    list user

user =
    succeed User
        |> required "name" string
        |> required "status" userStatus

userStatus =
    map userStatusFromString string

userStatusFromString a =
    case a of
        "active" -> Active
        "suspended" -> Suspended
        _ -> INVALID
