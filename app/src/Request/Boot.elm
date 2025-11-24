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

module Request.Boot exposing
    ( postScript
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

postScript : Model -> String -> Cmd Msg
postScript m s =
    Url.Builder.crossOrigin m.c.riakControlServerUrl [] []
        |> HttpBuilder.post
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withJsonBody (commandEncoder "exec_script" [("script", s)])
        |> HttpBuilder.withExpect (Http.expectWhatever ScriptPosted)
        |> HttpBuilder.request

commandEncoder a pp =
    let
        params = List.map (\(k, v) -> (k, Json.Encode.string v)) pp
    in
        Json.Encode.object
            [ ("action", Json.Encode.string a)
            , ("params", Json.Encode.object params)
            ]
