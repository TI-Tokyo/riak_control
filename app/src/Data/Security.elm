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

module Data.Security exposing (..)

import Dict exposing (Dict)
import Time


type Class
    = UserClass
    | GroupClass


-- type Permission
--     = ClusterAdmin
--     | ClusterObserver
--     | Security
--     | INVALID_PERMISSION

type Expires
    = Never
    | On Time.Posix

type AuthMethod
    = Password
    | INVALID_AUTHMETHOD

type alias User =
    { name : String
    , created : Time.Posix
    , modified : Time.Posix
    , expires : Expires
    , groups : List String
    , permissions : List String
    , authMethod : AuthMethod
    , tags : Dict.Dict String String
    }

dummyUser =
    { name = "-"
    , created = Time.millisToPosix 0
    , modified = Time.millisToPosix 0
    , expires = On (Time.millisToPosix 0)
    , groups = []
    , permissions = []
    , authMethod = Password
    , tags = Dict.empty
    }


type alias Group =
    { name : String
    , created : Time.Posix
    , modified : Time.Posix
    , permissions : List String
    , tags : Dict.Dict String String
    }

dummyGroup =
    { name = "-"
    , created = Time.millisToPosix 0
    , modified = Time.millisToPosix 0
    , permissions = []
    , tags = Dict.empty
    }


type SecurityAction
    = ListUsers
    | UserAdd String String Expires (Dict.Dict String String)
    | UserMod String (Dict.Dict String String)
    | UserDel String
    | AddUserGroups String (List String)
    | DeleteUserGroups String (List String)
    | AddUserPermissions String (List String)
    | DeleteUserPermissions String (List String)
    | ListGroups
    | GroupAdd String (Dict.Dict String String)
    | GroupMod String (Dict.Dict String String)
    | GroupDel String
    | AddGroupPermissions String (List String)
    | DeleteGroupPermissions String (List String)
    | ListPermissions


abbreviatePerm a =
    case a of
        "cluster_admin" -> "adm"
        "cluster_observer" -> "obs"
        "security" -> "sec"
        _ -> a
