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

module Data.Security exposing (..)

import Dict exposing (Dict)


type alias Grant =
    { scope : String
    , permissions : List String
    }

grantToStr : Grant -> String
grantToStr {scope, permissions} =
    scope ++ ":[" ++ (String.join "," permissions) ++ "]"

grantCrumbsFromStr : String -> List (String, String)
grantCrumbsFromStr s =
    let
        (scope, pps) =
            case String.split ":" s of
                [_, a1, a2] -> (a1, a2)
                _ -> ("", "")
        permissions = String.slice 1 -1 pps |> String.split ","
    in
        List.map (\p -> (p, scope)) permissions

type alias User =
    { name : String
    , groups : List String
    , password_hash : String
    , grants : List Grant
    , options : Dict.Dict String String
    }

dummyUser =
    { name = "-"
    , groups = []
    , password_hash = "-"
    , grants = []
    , options = Dict.empty
    }


type alias Group =
    { name : String
    , grants : List Grant
    , options : Dict.Dict String String
    }

dummyGroup =
    { name = "-"
    , grants = []
    , options = Dict.empty
    }

type Role
    = UserRole
    | GroupRole

type SecurityAction
    = ListUsers
    | UserAdd String (Dict.Dict String String)
    | UserMod String (Dict.Dict String String)
    | UserDel String
    | AddUserGroup String String
    | DeleteUserGroup String String
    | AddUserGrant String String String
    | DeleteUserGrant String String String
    | ListGroups
    | GroupAdd String (Dict.Dict String String)
    | GroupMod String (Dict.Dict String String)
    | GroupDel String
    | AddGroupGrant String String String
    | DeleteGroupGrant String String String
    | ListPermissions
