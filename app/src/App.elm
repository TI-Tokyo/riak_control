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

module App exposing (init, subscriptions, Flags)

import Model exposing (..)
import Update exposing (refreshAll)
import Msg exposing (Msg(..))
import View.Common exposing (SortByField(..))

import Dict exposing (Dict)
import Task
import Time
import Material.Snackbar as Snackbar

type alias Flags =
    { riakUrl : String
    , riakUser : String
    , riakPassword : String
    , riakAdminPathPrefix : String
    }


init : Flags -> (Model, Cmd Msg)
init f =
    let
        haveCreds = f.riakPassword /= ""
        config = Config f.riakUrl f.riakUser f.riakPassword f.rdrAdminPathPrefix
        state = State
                    []
                    Snackbar.initialQueue Msg.General True
                    { version = { otp = "---"
                                , riak = "---"
                                }
                    , config = Nothing
                    , configRaw = "---"
                    , uptime = { uptime = "---" }
                    } False
                    (not haveCreds) f.riakUrl f.riakUser f.riakPassword f.riakAdminPathPrefix
                    -- User
                    "" ["Name", "Display name"] Name True
                    False "" "" Nothing Nothing
        model = Model config state (Time.millisToPosix 0)
    in
        ( model
        , refreshAll model
        )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none
