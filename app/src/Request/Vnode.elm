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

module Request.Vnode exposing
    ( getVnodeStatus
    )

import Model exposing (Model)
import Data.Json
import Data.Vnode as Vnode
import Msg exposing (Msg(..))
import Util
import Request.Util exposing (..)

import Http
import HttpBuilder
import Url.Builder
import Json.Encode
import Json.Decode


getVnodeStatus : Model -> String -> Cmd Msg
getVnodeStatus m a =
    let
        -- a = m.s.vnodeStatusShownForNode
        b = Vnode.All
    in
        actionRequest m (Vnode.GetVnodeStatusAction a b) GotVnodeStatus

actionRequest m req msg =
    Url.Builder.crossOrigin m.c.riakNodeUrl [ "vnode" ] []
        |> HttpBuilder.post
        |> HttpBuilder.withJsonBody (requestParams req)
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectJson msg Data.Json.decodeVnodeStatusList)
        |> HttpBuilder.request

requestParams req =
    case req of
        Vnode.GetVnodeStatusAction a b ->
            Json.Encode.object
                [ ("action", Json.Encode.string "get_vnode_status")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string a)
                                                , ("preflists", Json.Encode.string (Vnode.preflistSelectionToStr b))
                                                ])
                ]
