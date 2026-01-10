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
    ( getReport
    )

import Model exposing (Model)
import Data.Json
import Data.Ttaae exposing (..)
import Msg exposing (Msg(..))
import Util
import Request.Util exposing (..)

import Http
import HttpBuilder
import Url.Builder
import Json.Encode
import Json.Decode


getReport : Model -> String -> Cmd Msg
getReport m a =
    let
        qs =
            if a == "" then
                []
            else
                [ Url.Builder.string "nodes" a ]
    in
        Url.Builder.crossOrigin m.c.riakNodeUrl [ "tictacaae" ] qs
            |> HttpBuilder.get
            |> HttpBuilder.withHeaders (stdHeaders m)
            |> HttpBuilder.withExpect (Http.expectJson GotTtaaeReport Data.Json.decodeTtaaeReport)
            |> HttpBuilder.request
