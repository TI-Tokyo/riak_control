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

module Request.Admin exposing
    ( getServerConfig
    , getServerVersion
    , getServerUptime
    , listUsers
    , createUser
    , deleteUser
    , updateUser
    )

import Model exposing (Model)
import Data.User exposing (User, Group)
import Data.Json
import Msg exposing (Msg(..))
import Util

import Iso8601
import Http
import HttpBuilder
import Url.Builder
import Json.Encode
import Base64
import Url


getServerConfig : Model -> Cmd Msg
getServerConfig m =
    Url.Builder.crossOrigin m.c.riakUrl [ m.c.riakAdminPathPrefix, "s", "config" ] []
        |> HttpBuilder.get
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectJson GotServerConfig Data.Json.decodeServerConfig)
        |> HttpBuilder.request

getServerUptime : Model -> Cmd Msg
getServerUptime m =
    Url.Builder.crossOrigin m.c.riakUrl [ m.c.riakAdminPathPrefix, "s", "uptime" ] []
        |> HttpBuilder.get
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectJson GotServerUptime Data.Json.decodeServerUptime)
        |> HttpBuilder.request

getServerVersion : Model -> Cmd Msg
getServerVersion m =
    Url.Builder.crossOrigin m.c.riakUrl [ m.c.riakAdminPathPrefix, "s", "version" ] []
        |> HttpBuilder.get
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectJson GotServerVersion Data.Json.decodeServerVersion)
        |> HttpBuilder.request



listUsers : Model -> Cmd Msg
listUsers m =
    Url.Builder.crossOrigin m.c.riakUrl [ m.c.riakAdminPathPrefix, "u" ] []
        |> HttpBuilder.get
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectJson GotUserList Data.Json.decodeUserList)
        |> HttpBuilder.request


createUser : Model -> Cmd Msg
createUser m  =
    let
        json = Json.Encode.object ([ ("name", Json.Encode.string m.s.newUserName)
                                   ])
        body = json |> Json.Encode.encode 0
        ct = "application/json"
    in
       Url.Builder.crossOrigin m.c.riakUrl [ m.c.riakAdminPathPrefix, "u" ] []
            |> HttpBuilder.post
            |> HttpBuilder.withHeaders (stdHeaders m)
            |> HttpBuilder.withExpect (Http.expectWhatever UserCreated)
            |> HttpBuilder.withStringBody ct body
            |> HttpBuilder.request

updateUser : Model -> Cmd Msg
updateUser m  =
    let
        u = Maybe.withDefault Data.User.dummyUser m.s.openEditUserDialogFor
        json = Json.Encode.object ([ ("name", Json.Encode.string u.name)
                                   , ("status", Json.Encode.string (Data.User.userStatusToString u.status))
                                   ])
        body = json |> Json.Encode.encode 0
        ct = "application/json"
    in
       Url.Builder.crossOrigin m.c.riakUrl [ m.c.riakAdminPathPrefix, "u", u.id ] []
            |> HttpBuilder.put
            |> HttpBuilder.withHeaders (stdHeaders m)
            |> HttpBuilder.withExpect (Http.expectWhatever UserCreated)
            |> HttpBuilder.withStringBody ct body
            |> HttpBuilder.request


stdHeaders m =
    let ct = "application/json" in
    [ ("accept", ct)
    , ("content-type", ct)
    , ("authorization",
        "Basic " ++ (Base64.encode ("root" ++ ":" ++ m.c.rdrRootPassword)))
    ]
