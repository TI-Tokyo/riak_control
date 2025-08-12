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
    ( pingTask
    , getServerInfo
    )

import Model exposing (Model)
import Data.Json
import Msg exposing (Msg(..))
import Util
import Request.Util exposing (..)

import Http
import HttpBuilder
import HttpBuilder.Task
import Url.Builder
import Json.Encode
import Base64
import Task


pingTask m =
    let
        url = Url.Builder.crossOrigin m.c.riakNodeUrl [ "ping" ] []
        headers = [ ("accept", "*")
                  , ("authorization",
                         "Basic " ++ (Base64.encode (m.c.riakAdminUser ++ ":" ++ m.c.riakAdminPassword)))
                  ]
    in
        Http.task
            { url = url
            , method = "get"
            , headers = List.map (\(h, v) -> Http.header h v) headers
            , body = Http.emptyBody
            , resolver = Http.stringResolver pingResolver
            , timeout = Nothing
            }

pingResolver a =
    case a of
        Http.GoodStatus_ _ body ->
            case body of
                "OK" ->
                    Ok "OK"
                err ->
                    Err (Http.BadBody <| "Bad pong: " ++ err)
        Http.BadStatus_ md _ ->
            Err (Http.BadStatus md.statusCode)
        _ ->
            Err (Http.NetworkError)

getServerInfo : Model -> Cmd Msg
getServerInfo m =
    Url.Builder.crossOrigin m.c.riakNodeUrl [ "system_info" ] []
        |> HttpBuilder.get
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectJson GotServerInfo Data.Json.decodeServerInfo)
        |> HttpBuilder.request
