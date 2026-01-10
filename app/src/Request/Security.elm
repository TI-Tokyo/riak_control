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

module Request.Security exposing
    ( listUsers
    , createUser
    , deleteUser
    , updateUser
    , addUserGroup
    , deleteUserGroup
    , addUserGrant
    , deleteUserGrant

    , listGroups
    , createGroup
    , deleteGroup
    , updateGroup
    , addGroupGrant
    , deleteGroupGrant

    , listPermissions
    )

import Model exposing (Model)
import Data.Security exposing (..)
import Data.Json
import Msg exposing (Msg(..))
import Util
import Request.Util exposing (..)

import Dict
import Http
import HttpBuilder
import Url.Builder
import Json.Encode exposing (string, dict)
import Url


listUsers : Model -> Cmd Msg
listUsers m =
    securityRequest m (Http.expectJson GotUserList Data.Json.decodeUserList)
        Data.Security.ListUsers

createUser : Model -> Cmd Msg
createUser m  =
    securityRequest m (Http.expectWhatever UserCreated)
        (Data.Security.UserAdd m.s.newUserName
             (Dict.fromList [("password",  m.s.newUserPassword)]))

updateUser : Model -> Cmd Msg
updateUser m  =
    securityRequest m (Http.expectWhatever UserCreated)
        (Data.Security.UserMod m.s.newUserName
             (Dict.fromList [("password",  m.s.newUserPassword)]))

addUserGroup : Model -> String -> Cmd Msg
addUserGroup m a =
    securityRequest m (Http.expectWhatever UserGroupAdded)
        (Data.Security.AddUserGroup
             (Maybe.withDefault "--" m.s.openEditUserGroupsDialogFor) a)

deleteUserGroup : Model -> String -> Cmd Msg
deleteUserGroup m a =
    securityRequest m (Http.expectWhatever UserGroupAdded)
        (Data.Security.DeleteUserGroup
             (Maybe.withDefault "--" m.s.openEditUserGroupsDialogFor) a)

addUserGrant : Model -> String -> String -> Cmd Msg
addUserGrant m a b =
    securityRequest m (Http.expectWhatever UserGrantAdded)
        (Data.Security.AddUserGrant
             (Maybe.withDefault "--" m.s.openAddGrantsDialogFor) a b)

deleteUserGrant : Model -> String -> String -> Cmd Msg
deleteUserGrant m a b =
    securityRequest m (Http.expectWhatever UserGrantDeleted)
        (Data.Security.DeleteUserGrant
             (Maybe.withDefault "--" m.s.openEditGrantsDialogFor) a b)

deleteUser : Model -> String -> Cmd Msg
deleteUser m a =
    securityRequest m (Http.expectWhatever UserCreated)
        (Data.Security.UserDel a)


listGroups : Model -> Cmd Msg
listGroups m =
    securityRequest m (Http.expectJson GotGroupList Data.Json.decodeGroupList)
        Data.Security.ListGroups

createGroup : Model -> Cmd Msg
createGroup m  =
    securityRequest m (Http.expectWhatever GroupCreated)
        (Data.Security.GroupAdd m.s.newGroupName
             (Dict.fromList []))

updateGroup : Model -> Cmd Msg
updateGroup m  =
    securityRequest m (Http.expectWhatever GroupCreated)
        (Data.Security.GroupMod m.s.newGroupName
             (Dict.fromList []))

deleteGroup : Model -> String -> Cmd Msg
deleteGroup m a =
    securityRequest m (Http.expectWhatever GroupCreated)
        (Data.Security.GroupDel a)

addGroupGrant : Model -> String -> String -> Cmd Msg
addGroupGrant m a b =
    securityRequest m (Http.expectWhatever GroupGrantAdded)
        (Data.Security.AddGroupGrant
             (Maybe.withDefault "--" m.s.openAddGrantsDialogFor) a b)

deleteGroupGrant : Model -> String -> String -> Cmd Msg
deleteGroupGrant m a b =
    securityRequest m (Http.expectWhatever GroupGrantDeleted)
        (Data.Security.DeleteGroupGrant
             (Maybe.withDefault "--" m.s.openEditGrantsDialogFor) a b)

securityRequest m expect a =
    Url.Builder.crossOrigin m.c.riakNodeUrl [ "security"  ] []
        |> HttpBuilder.post
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect expect
        |> HttpBuilder.withJsonBody (securityActionEncoder a)
        |> HttpBuilder.request


listPermissions : Model -> Cmd Msg
listPermissions m =
    securityRequest m (Http.expectJson GotPermissionList Data.Json.decodePermissionList)
        Data.Security.ListPermissions



securityActionEncoder action =
    case action of
        Data.Security.ListUsers ->
            Json.Encode.object
                [ ("action", string "ListUsers")
                , ("params", Json.Encode.object [])
                ]

        Data.Security.UserAdd name options ->
            Json.Encode.object
                [ ("action", string "CreateUser")
                , ("params", Json.Encode.object [ ("name", string name)
                                                , ("options", dict identity string options)
                                                ])
                ]
        Data.Security.UserMod name options ->
            Json.Encode.object
                [ ("action", string "UpdateUser")
                , ("params", Json.Encode.object [ ("name", string name)
                                                , ("options", dict identity string options)
                                                ])
                ]
        Data.Security.UserDel name ->
            Json.Encode.object
                [ ("action", string "DeleteUser")
                , ("params", Json.Encode.object [ ("name", string name)
                                                ])
                ]

        Data.Security.AddUserGroup u g ->
            Json.Encode.object
                [ ("action", string "AddUserGroup")
                , ("params", Json.Encode.object [ ("user", string u)
                                                , ("group", string g)
                                                ])
                ]
        Data.Security.DeleteUserGroup u g ->
            Json.Encode.object
                [ ("action", string "DeleteUserGroup")
                , ("params", Json.Encode.object [ ("user", string u)
                                                , ("group", string g)
                                                ])
                ]

        Data.Security.AddUserGrant u a b ->
            Json.Encode.object
                [ ("action", string "AddUserGrant")
                , ("params", Json.Encode.object [ ("user", string u)
                                                , ("permission", string a)
                                                , ("scope", string b)
                                                ])
                ]
        Data.Security.DeleteUserGrant u a b ->
            Json.Encode.object
                [ ("action", string "DeleteUserGrant")
                , ("params", Json.Encode.object [ ("user", string u)
                                                , ("permission", string a)
                                                , ("scope", string b)
                                                ])
                ]

        Data.Security.ListGroups ->
            Json.Encode.object
                [ ("action", string "ListGroups")
                , ("params", Json.Encode.object [])
                ]
        Data.Security.GroupAdd name options ->
            Json.Encode.object
                [ ("action", string "CreateGroup")
                , ("params", Json.Encode.object [ ("name", string name)
                                                , ("options", dict identity string options)
                                                ])
                ]
        Data.Security.GroupMod name options ->
            Json.Encode.object
                [ ("action", string "UpdateGroup")
                , ("params", Json.Encode.object [ ("name", string name)
                                                , ("options", dict identity string options)
                                                ])
                ]
        Data.Security.GroupDel name ->
            Json.Encode.object
                [ ("action", string "DeleteGroup")
                , ("params", Json.Encode.object [ ("name", string name)
                                                ])
                ]

        Data.Security.AddGroupGrant u a b ->
            Json.Encode.object
                [ ("action", string "AddGroupGrant")
                , ("params", Json.Encode.object [ ("group", string u)
                                                , ("permission", string a)
                                                , ("scope", string b)
                                                ])
                ]
        Data.Security.DeleteGroupGrant u a b ->
            Json.Encode.object
                [ ("action", string "DeleteGroupGrant")
                , ("params", Json.Encode.object [ ("group", string u)
                                                , ("permission", string a)
                                                , ("scope", string b)
                                                ])
                ]

        Data.Security.ListPermissions ->
            Json.Encode.object
                [ ("action", string "ListPermissions")
                , ("params", Json.Encode.object [])
                ]
