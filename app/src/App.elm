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

module App exposing (init, subscriptions, Flags)

import Model exposing (..)
import Data.Cluster
import Data.SshOps
import Data.VersionInfo
import Update exposing (refreshAll)
import Msg exposing (Msg(..))
import View.Common exposing (SortByField(..))
import Static

import Dict exposing (Dict)
import Task
import Time
import RemoteData
import Material.Snackbar as Snackbar

type alias Flags =
    { riakControlServerUrl : String
    , riakControlServerUser : String
    , riakControlServerPassword : String
    , riakNodePingUrl : String
    , riakAdminCtlUrl : String
    , riakAdminCtlUser : String
    , riakAdminCtlPassword : String
    }


init : Flags -> (Model, Cmd Msg)
init f =
    let
        haveCreds = f.riakAdminCtlPassword /= ""
        config =
            Config
                f.riakControlServerUrl f.riakControlServerUser f.riakControlServerPassword
                f.riakAdminCtlUrl f.riakAdminCtlUser f.riakAdminCtlPassword
                f.riakNodePingUrl
                3000
        state =
            State
                Data.Cluster.emptyCluster
                Dict.empty Dict.empty [] Nothing
                [] [] []
                Snackbar.initialQueue Msg.Connection True
                -- boot
                False f.riakControlServerUser f.riakControlServerPassword
                [] "" "(script-template-id)" False
                []
                False "(new key id)" "(new key body)"
                False "(key id to delete)"
                "(current-session-id)"
                Static.awaitingOutput
                Data.SshOps.ScriptNotStarted
                -- config
                (Dict.fromList [("", Data.VersionInfo.emptyVersionInfo)])
                (not haveCreds) f.riakNodePingUrl f.riakAdminCtlUrl f.riakAdminCtlUser f.riakAdminCtlPassword
                -- Cluster
                "(awaiting refresh)" SortName True Nothing Nothing
                False ""  ""
                "" "" "(replacement)"
                False
                -- User
                "" ["Name"] SortName True
                False "(newUserName)" "(newUserPassword)" "(newUserExpires)" "(newUserTags)"
                Nothing Nothing
                Nothing "(editedUserExpires)" "(editedUserTags)"
                Nothing [] []
                -- Group
                "" ["Name", "Tag name", "Tag value"] SortName True
                False "" Nothing Nothing
                -- shared
                Nothing Nothing  [] ""
                -- TictacAAE
                Dict.empty ""
                "" [] SortUnsorted False
                -- Vnode
                [] ""
                "" [] SortUnsorted False False
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
    if m.s.activeTab == Msg.Cluster then
        Time.every m.c.refreshEvery Tick
    else
        Sub.none
