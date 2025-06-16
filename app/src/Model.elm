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

module Model exposing
    ( Model
    , Config
    , State
    , userBy
    )

import Data.Server exposing (..)
import Data.User exposing (..)

import Msg
import View.Common exposing (SortOrder, SortByField)

import Material.Snackbar as Snackbar
import Time
import Dict


type alias Model =
    { c : Config
    , s : State
    , t : Time.Posix
    }

type alias Config =
    { riakNodeUrl : String
    , riakAdminUser : String
    , riakAdminPassword : String
    }

type alias State =
    { users : List User

    , msgQueue : Snackbar.Queue Msg.Msg
    , activeTab : Msg.Tab
    , topDrawerOpen : Bool

    -- general
    , serverInfo : ServerInfo
    --
    , configDialogShown : Bool
    , newConfigRiakNodeUrl : String
    , newConfigRiakAdminUser : String
    , newConfigRiakAdminPassword : String

    -- users
    , userFilterValue : String
    , userFilterIn : List String
    , userSortBy : SortByField
    , userSortOrder : SortOrder
    --
    , createUserDialogShown : Bool
    , newUserName : String
    , newUserPassword : String
    , openEditUserDialogFor : Maybe User
    , confirmDeleteUserDialogShownFor : Maybe String

    }


userBy : Model -> (User -> String) -> String -> User
userBy m by a =
    case List.filter (\u -> a == by u) m.s.users of
        [] -> Data.User.dummyUser
        u :: _ -> u
