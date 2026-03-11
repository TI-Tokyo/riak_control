-- ---------------------------------------------------------------------
--
-- Copyright (c) 2026 TI Tokyo    All Rights Reserved.
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

module Request.Ttaae exposing
    ( getStatus
    )

import Model exposing (Model)
import Data.Json
import Data.Ttaae as Ttaae
import Msg exposing (Msg(..))
import Util
import Request.Util exposing (..)

import Http
import HttpBuilder
import Url.Builder
import Json.Encode
import Json.Decode

getStatus : Model -> String -> Cmd Msg
getStatus m a =
    actionRequest m (Ttaae.GetTtaaeStatusAction a) GotTtaaeStatus

actionRequest m req msg =
    Url.Builder.crossOrigin m.c.riakNodeUrl [ "ctl" ] []
        |> HttpBuilder.post
        |> HttpBuilder.withJsonBody (requestParams req)
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectJson GotTtaaeStatus Data.Json.decodeTtaaeStatus)
        |> HttpBuilder.request

requestParams req =
    case req of
        Ttaae.GetTtaaeStatusAction a ->
            Json.Encode.object
                [ ("action", Json.Encode.string "TictacaaeGetStatus")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string a)
                                                ])
                ]
