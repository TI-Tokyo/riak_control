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
    , addUserPermissions
    , deleteUserPermissions

    , listGroups
    , createGroup
    , deleteGroup
    , updateGroup
    , addGroupPermissions
    , deleteGroupPermissions

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
import Json.Encode exposing (string, dict, list)
import Url
import Iso8601


listUsers : Model -> Cmd Msg
listUsers m =
    securityRequest m (Http.expectJson GotUserList Data.Json.decodeUserList)
        Data.Security.ListUsers

createUser : Model -> Cmd Msg
createUser m  =
    securityRequest m (Http.expectWhatever UserCreated)
        (Data.Security.UserAdd m.s.newUserName m.s.newUserPassword Never Dict.empty)

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

addUserPermissions : Model -> (List String) -> Cmd Msg
addUserPermissions m aa =
    securityRequest m (Http.expectWhatever UserPermissionsAdded)
        (Data.Security.AddUserPermissions
             (Maybe.withDefault "--" m.s.openAddPermissionsDialogFor) aa)

deleteUserPermissions : Model -> (List String) -> Cmd Msg
deleteUserPermissions m aa =
    securityRequest m (Http.expectWhatever UserPermissionsDeleted)
        (Data.Security.DeleteUserPermissions
             (Maybe.withDefault "--" m.s.openEditPermissionsDialogFor) aa)

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

addGroupPermissions : Model -> (List String) -> Cmd Msg
addGroupPermissions m aa =
    securityRequest m (Http.expectWhatever GroupPermissionsAdded)
        (Data.Security.AddGroupPermissions
             (Maybe.withDefault "--" m.s.openAddPermissionsDialogFor) aa)

deleteGroupPermissions : Model -> (List String) -> Cmd Msg
deleteGroupPermissions m aa =
    securityRequest m (Http.expectWhatever GroupPermissionsDeleted)
        (Data.Security.DeleteGroupPermissions
             (Maybe.withDefault "--" m.s.openEditPermissionsDialogFor) aa)

securityRequest m expect a =
    Url.Builder.crossOrigin m.c.riakAdminCtlUrl [ "ctl"  ] []
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
                [ ("action", string "SecurityListUsers")
                , ("params", Json.Encode.object [])
                ]

        Data.Security.UserAdd name password expires tags ->
            let
                jo = Json.Encode.object
                expiresObj =
                    case expires of
                        Never -> string "never"
                        On a -> Iso8601.encode a
            in
            Json.Encode.object
                [ ("action", string "SecurityCreateUser")
                , ("params", jo [ ("name", string name)
                                , ("auth_details", jo [ ("method", string "password")
                                                      , ("password", string password)
                                                      ]
                                  )
                                , ("expires", expiresObj)
                                , ("tags", dict identity string tags)
                                ])
                ]
        Data.Security.UserMod name options ->
            Json.Encode.object
                [ ("action", string "SecurityUpdateUser")
                , ("params", Json.Encode.object [ ("name", string name)
                                                , ("options", dict identity string options)
                                                ])
                ]
        Data.Security.UserDel name ->
            Json.Encode.object
                [ ("action", string "SecurityDeleteUser")
                , ("params", Json.Encode.object [ ("name", string name)
                                                ])
                ]

        Data.Security.AddUserGroup u g ->
            Json.Encode.object
                [ ("action", string "SecurityAddUserGroup")
                , ("params", Json.Encode.object [ ("user", string u)
                                                , ("group", string g)
                                                ])
                ]
        Data.Security.DeleteUserGroup u g ->
            Json.Encode.object
                [ ("action", string "SecurityDeleteUserGroup")
                , ("params", Json.Encode.object [ ("user", string u)
                                                , ("group", string g)
                                                ])
                ]

        Data.Security.AddUserPermissions u aa ->
            Json.Encode.object
                [ ("action", string "SecurityAddUserPermissions")
                , ("params", Json.Encode.object [ ("user", string u)
                                                , ("permissions", list string aa)
                                                ])
                ]
        Data.Security.DeleteUserPermissions u aa ->
            Json.Encode.object
                [ ("action", string "SecurityDeleteUserPermissions")
                , ("params", Json.Encode.object [ ("user", string u)
                                                , ("permissions", list string aa)
                                                ])
                ]

        Data.Security.ListGroups ->
            Json.Encode.object
                [ ("action", string "SecurityListGroups")
                , ("params", Json.Encode.object [])
                ]
        Data.Security.GroupAdd name options ->
            Json.Encode.object
                [ ("action", string "SecurityCreateGroup")
                , ("params", Json.Encode.object [ ("name", string name)
                                                , ("options", dict identity string options)
                                                ])
                ]
        Data.Security.GroupMod name options ->
            Json.Encode.object
                [ ("action", string "SecurityUpdateGroup")
                , ("params", Json.Encode.object [ ("name", string name)
                                                , ("options", dict identity string options)
                                                ])
                ]
        Data.Security.GroupDel name ->
            Json.Encode.object
                [ ("action", string "SecurityDeleteGroup")
                , ("params", Json.Encode.object [ ("name", string name)
                                                ])
                ]

        Data.Security.AddGroupPermissions u aa ->
            Json.Encode.object
                [ ("action", string "SecurityAddGroupPermissions")
                , ("params", Json.Encode.object [ ("group", string u)
                                                , ("permissions", list string aa)
                                                ])
                ]
        Data.Security.DeleteGroupPermissions u aa ->
            Json.Encode.object
                [ ("action", string "SecurityDeleteGroupPermissions")
                , ("params", Json.Encode.object [ ("group", string u)
                                                , ("permissions", list string aa)
                                                ])
                ]

        Data.Security.ListPermissions ->
            Json.Encode.object
                [ ("action", string "SecurityListPermissions")
                , ("params", Json.Encode.object [])
                ]
