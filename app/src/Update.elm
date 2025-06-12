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

module Update exposing
    ( update
    , refreshAll
    )

import Model exposing (..)
import Msg exposing (Msg(..))
import Request.Admin
import Data.User exposing (UserStatus(..), dummyUser)
import Data.Json
import View.Common
import Util

import Time
import Task exposing (attempt, perform, andThen, succeed, sequence)
import Platform.Cmd
import Dict exposing (Dict)
import Json.Decode
import Http
import Material.Snackbar as Snackbar


update : Msg -> Model -> (Model, Cmd Msg)
update msg m =
    case msg of
        TabClicked t ->
            let s_ = m.s in
            ( {m | s = {s_ | activeTab = t, topDrawerOpen = False}}
            , refreshTabMsg m t
            )
        OpenTopDrawer ->
            let s_ = m.s in
            ( {m | s = {s_ | topDrawerOpen = not s_.topDrawerOpen}}
            , Cmd.none
            )

        -- ServerInfo
        ------------------------------
        GetServerVersion ->
            (m, Request.Admin.getServerVersion m)
        GotServerVersion (Ok a) ->
            let
                s_ = m.s
                si_ = s_.serverInfo
            in
                ({m | s = {s_ | serverInfo = {si_ | version = a}}}, Cmd.none)
        GotServerVersion (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | users = [], msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to get server config: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        GetServerUptime ->
            (m, Request.Admin.getServerUptime m)
        GotServerUptime (Ok a) ->
            let
                s_ = m.s
                si_ = s_.serverInfo
            in
                ({m | s = {s_ | serverInfo = {si_ | uptime = a}}}, Cmd.none)
        GotServerUptime (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | users = [], msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to get server uptime: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )


        -- Admin creds
        ------------------------------
        ShowConfigDialog ->
            let s_ = m.s in
            ({m | s = {s_ | configDialogShown = True}}, Cmd.none)
        ConfigRiakNodeUrlChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigRiakNodeUrl = s}}, Cmd.none)
        ConfigRiakAdminUserChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigRiakAdminUser = s}}, Cmd.none)
        ConfigRiakAdminPasswordChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigRiakAdminPassword = s}}, Cmd.none)
        SetConfig ->
            let
                c_ = m.c
                s_ = m.s
            in
            ( { m | c = {c_ | riakNodeUrl = m.s.newConfigRiakNodeUrl
                            , riakAdminUser = m.s.newConfigRiakAdminUser
                            , riakAdminPassword = m.s.newConfigRiakAdminPassword
                        },
                    s = {s_ | configDialogShown = False}
              }
            , Cmd.none
            )
        SetConfigCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | configDialogShown = False}}, Cmd.none)


        -- User
        ------------------------------
        UserFilterChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | userFilterValue = s}}, Cmd.none)
        UserFilterInItemClicked s ->
            let s_ = m.s in
            ({m | s = {s_ | userFilterIn = Util.addOrDeleteElement s_.userFilterIn s}}, Cmd.none)
        UserSortByFieldChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | userSortBy = View.Common.stringToSortBy s}}, Cmd.none)
        UserSortOrderChanged ->
            let s_ = m.s in
            ({m | s = {s_ | userSortOrder = not s_.userSortOrder}}, Cmd.none)

        ListUsers ->
            (m, Request.Admin.listUsers m)
        GotUserList (Ok users) ->
            let s_ = m.s in
            ({m | s = { s_ | users = users}}, Cmd.none)
        GotUserList (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | users = [], msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to fetch users: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        ShowCreateUserDialog ->
            let s_ = m.s in
            ({m | s = {s_ | createUserDialogShown = True}}, Cmd.none)
        NewUserNameChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | newUserName = a}}, Cmd.none)
        NewUserPasswordChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | newUserPassword = a}}, Cmd.none)
        CreateUser ->
            (m, Request.Admin.createUser m)
        CreateUserCancelled ->
            (resetCreateUserDialogFields m, Cmd.none)
        UserCreated (Ok ()) ->
            (resetCreateUserDialogFields m, Cmd.batch [ Request.Admin.listUsers m
                                                      ])
        UserCreated (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to create user: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        DeleteUser a ->
            let s_ = m.s in
            ( {m | s = {s_ | confirmDeleteUserDialogShownFor = Just a}}, Cmd.none )
        DeleteUserConfirmed ->
            let
                s_ = m.s
                a = Maybe.withDefault "" m.s.confirmDeleteUserDialogShownFor
            in
                ( {m | s = {s_ | confirmDeleteUserDialogShownFor = Nothing}}
                , Request.Admin.deleteUser m a
                )
        DeleteUserNotConfirmed ->
            let s_ = m.s in
            ( {m | s = {s_ | confirmDeleteUserDialogShownFor = Nothing}}, Cmd.none )
        UserDeleted (Ok ()) ->
            (m, Request.Admin.listUsers m)
        UserDeleted (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to delete user: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        ShowEditUserDialog u ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserDialogFor = Just u}}, Cmd.none)
        EditedUserStatusChanged ->
            let
                s_ = m.s
                u_ = Maybe.withDefault dummyUser m.s.openEditUserDialogFor
            in
                ({m | s = {s_ | openEditUserDialogFor = Just {u_ | status = toggleStatus u_.status}}}, Cmd.none)
        UpdateUser ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserDialogFor = Nothing}}, Request.Admin.updateUser m)
        EditUserCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserDialogFor = Nothing}}, Cmd.none)


        -- Notifications
        ------------------------------
        SnackbarClosed a ->
            let
                s_ = m.s
                b = Snackbar.close a m.s.msgQueue
            in
                ({m | s = {s_ | msgQueue = b}}, Cmd.none)

        NewTime t ->
            ({m|t = t}, Cmd.none)

        NoOp ->
            (m, Cmd.none)
        Discard _ ->
            (m, Cmd.none)


refreshTabMsg m t =
    case t of
        Msg.General -> Cmd.batch [ Request.Admin.getServerVersion m
                                 , Request.Admin.getServerUptime m
                                 ]
        Msg.Users -> Request.Admin.listUsers m

refreshAll m =
    Cmd.batch [ Request.Admin.getServerVersion m
              , Request.Admin.getServerUptime m
              , Request.Admin.listUsers m
              ]

resetCreateUserDialogFields m =
    let s_ = m.s in
    {m | s = {s_ | createUserDialogShown = False
                 , newUserName = ""
             }
    }

explainHttpError a =
    case a of
        Http.BadBody s ->
            "" ++ (Util.ellipsize s 500)
        Http.Timeout ->
            "Request timed out"
        Http.NetworkError ->
            "Network error"
        Http.BadStatus s ->
            "Bad status " ++ String.fromInt s
        Http.BadUrl s ->
            "BadUrl. This shouldn't have happened."

toggleStatus a =
    case a of
        Active -> Suspended
        _ -> Active
