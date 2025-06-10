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

module Msg exposing
    ( Msg(..)
    , Tab(..)
    , getNewTime
    )

import Data.User exposing
    ( User
    )
import Data.Server exposing
    ( ServerInfo
    , ServerUptime
    , ServerVersion
    , ServerConfig
    )

import Task
import Http
import Time
import Material.Snackbar as Snackbar
import File exposing (File)
import Bytes exposing (Bytes)
import Keyboard exposing (RawKey)


type Tab
    = General

type Msg
    = NoOp
    | Discard String

    -- General
    ----------
    | GetServerConfig
    | GotServerConfig (Result Http.Error ServerConfig)
    | GetServerVersion
    | GotServerVersion (Result Http.Error ServerVersion)
    | GetServerUptime
    | GotServerUptime (Result Http.Error ServerUptime)

    -- Users
    | ListUsers
    | GotUserList (Result Http.Error (List User))
    | CreateUser
    | UserCreated (Result Http.Error ())
    | DeleteUser String
    | DeleteUserConfirmed
    | DeleteUserNotConfirmed
    | UserDeleted (Result Http.Error ())
    | UpdateUser

    -- UI interactions
    ------------------
    | TabClicked Tab
    | OpenTopDrawer
    | ShowConfigDialog
    | ConfigUrlChanged String
    | ConfigUserChanged String
    | ConfigPasswordChanged String
    | ConfigAdminPathPrefixChanged String
    | SetConfig
    | SetConfigCancelled

    | ShowServerConfig
    | ServerConfigDialogDismissed

    -- users
    | UserFilterChanged String
    | UserFilterInItemClicked String
    | UserSortByFieldChanged String
    | UserSortOrderChanged

    | ShowCreateUserDialog
    | NewUserNameChanged String
    | NewUserPasswordChanged String
    | CreateUserCancelled
    | ShowEditUserDialog User
    | EditedUserStatusChanged
    | EditUserCancelled

    -- misc
    | KeyboardMsg Keyboard.Msg
    | SnackbarClosed Snackbar.MessageId

    | NewTime Time.Posix


getNewTime : Cmd Msg
getNewTime =
  Task.perform NewTime Time.now
