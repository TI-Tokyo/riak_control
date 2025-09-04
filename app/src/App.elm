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
import Data.Cluster
import Update exposing (refreshAll)
import Msg exposing (Msg(..))
import View.Common exposing (SortByField(..))

import Dict exposing (Dict)
import Task
import Time
import Material.Snackbar as Snackbar

type alias Flags =
    { riakNodeUrl : String
    , riakAdminUser : String
    , riakAdminPassword : String
    }


init : Flags -> (Model, Cmd Msg)
init f =
    let
        haveCreds = f.riakAdminPassword /= ""
        config =
            Config
                f.riakNodeUrl f.riakAdminUser f.riakAdminPassword
                3000
        state =
            State
                Data.Cluster.emptyCluster
                Dict.empty Dict.empty [] Nothing
                [] [] []
                Snackbar.initialQueue Msg.General True
                { riakVersion = "---"
                , systemVersion = "---"
                , uptime = 0
                , uptimeStr = "---"
                }
                (not haveCreds) f.riakNodeUrl f.riakAdminUser f.riakAdminPassword
                -- Cluster
                "(awaiting refresh)" Name True Nothing Nothing
                False ""  ""
                "" "" "(replacement)"
                False
                -- User
                "" ["Name"] Name True
                False "(newUserName)" "(newUserPassword)" Nothing Nothing
                Nothing Nothing [] []
                -- Group
                "" ["Name"] Name True
                False "" Nothing Nothing
                -- shared
                Nothing Nothing  [] "" ""
                -- TictacAAE
                Dict.empty ""
                "" [] TtaaeTreeStatus False
        model =
            Model
                config
                state
                (Time.millisToPosix 0)
    in
        ( model
        , refreshAll model
        )


subscriptions : Model -> Sub Msg
subscriptions m =
    Time.every m.c.refreshEvery Tick
