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
import Data.Security.Lib as Lib
import Data.Json
import Msg exposing (Msg(..))
import Util
import Request.Util exposing (..)

import Time
import Dict
import Http
import HttpBuilder
import Url.Builder
import Json.Encode as JE exposing (list, string, dict, object)
import Json.Decode as JD
import Url
import Iso8601


listUsers : Model -> Cmd Msg
listUsers m =
    securityRequest m "SecurityListUsers"
        (Http.expectJson GotUserList Data.Json.decodeUserList)
        Data.Security.ListUsers

createUser : Model -> Time.Posix -> Cmd Msg
createUser m now =
    let
        expires = Lib.convertExpires m.s.newUserExpiresIn now
        tags =
            case JD.decodeString (JD.dict JD.string) m.s.newUserTags of
                Ok res -> res
                Err _ ->  Dict.empty
    in
    case expires of
        Ok expValue ->
            securityRequest m "SecurityCreateUser"
                (Http.expectWhatever UserCreated)
                (Data.Security.UserAdd m.s.newUserName m.s.newUserPassword expValue tags)
        Err _ ->
            Cmd.none

updateUser : Model -> Cmd Msg
updateUser m  =
    securityRequest m "SecurityUpdateUser"
        (Http.expectWhatever UserCreated)
        (Data.Security.UserMod m.s.newUserName
             (Dict.fromList [("password",  m.s.newUserPassword)]))

addUserGroup : Model -> String -> Cmd Msg
addUserGroup m a =
    securityRequest m "SecurityAddUserGroups"
        (Http.expectWhatever UserGroupAdded)
        (Data.Security.AddUserGroups
             (Maybe.withDefault "--" m.s.openEditUserGroupsDialogFor) [a])

deleteUserGroup : Model -> String -> Cmd Msg
deleteUserGroup m a =
    securityRequest m "SecurityDeleteUserGroups"
        (Http.expectWhatever UserGroupAdded)
        (Data.Security.DeleteUserGroups
             (Maybe.withDefault "--" m.s.openEditUserGroupsDialogFor) [a])

addUserPermissions : Model -> (List String) -> Cmd Msg
addUserPermissions m aa =
    securityRequest m "SecurityAddUserPermissions"
        (Http.expectWhatever UserPermissionsAdded)
        (Data.Security.AddUserPermissions
             (Maybe.withDefault "--" m.s.openAddPermissionsDialogFor) aa)

deleteUserPermissions : Model -> (List String) -> Cmd Msg
deleteUserPermissions m aa =
    securityRequest m "SecurityDeleteUserPermissions"
        (Http.expectWhatever UserPermissionsDeleted)
        (Data.Security.DeleteUserPermissions
             (Maybe.withDefault "--" m.s.openEditPermissionsDialogFor) aa)

deleteUser : Model -> String -> Cmd Msg
deleteUser m a =
    securityRequest m "SecurityDeleteUser"
        (Http.expectWhatever UserCreated)
        (Data.Security.UserDel a)


listGroups : Model -> Cmd Msg
listGroups m =
    securityRequest m "SecurityListGroups"
        (Http.expectJson GotGroupList Data.Json.decodeGroupList)
        Data.Security.ListGroups

createGroup : Model -> Cmd Msg
createGroup m  =
    securityRequest m "SecurityCreateGroup"
        (Http.expectWhatever GroupCreated)
        (Data.Security.GroupAdd m.s.newGroupName
             (Dict.fromList []))

updateGroup : Model -> Cmd Msg
updateGroup m  =
    securityRequest m "SecurityUpdateGroup"
        (Http.expectWhatever GroupCreated)
        (Data.Security.GroupMod m.s.newGroupName
             (Dict.fromList []))

deleteGroup : Model -> String -> Cmd Msg
deleteGroup m a =
    securityRequest m "SecurityDeleteGroup"
        (Http.expectWhatever GroupCreated)
        (Data.Security.GroupDel a)

addGroupPermissions : Model -> (List String) -> Cmd Msg
addGroupPermissions m aa =
    securityRequest m "SecurityAddGroupPermissions"
        (Http.expectWhatever GroupPermissionsAdded)
        (Data.Security.AddGroupPermissions
             (Maybe.withDefault "--" m.s.openAddPermissionsDialogFor) aa)

deleteGroupPermissions : Model -> (List String) -> Cmd Msg
deleteGroupPermissions m aa =
    securityRequest m "SecurityDeleteGroupPermissions"
        (Http.expectWhatever GroupPermissionsDeleted)
        (Data.Security.DeleteGroupPermissions
             (Maybe.withDefault "--" m.s.openEditPermissionsDialogFor) aa)

listPermissions : Model -> Cmd Msg
listPermissions m =
    securityRequest m "SecurityListPermissions"
        (Http.expectJson GotPermissionList Data.Json.decodePermissionList)
        Data.Security.ListPermissions

securityRequest m action expect c =
    Request.Util.req m action (securityActionEncoder c) expect

securityActionEncoder action =
    case action of
        Data.Security.ListUsers ->
            object [ ("params", object []) ]

        Data.Security.UserAdd name password expires tags ->
            let
                jo = object
                expiresObj =
                    case expires of
                        Never -> string "never"
                        On a -> Iso8601.encode a
            in
                object
                    [ ("params", jo [ ("name", string name)
                                    , ("auth_details", jo [ ("method", string "password")
                                                          , ("password", string password)
                                                          ]
                                      )
                                    , ("expires", expiresObj)
                                    , ("tags", dict identity string tags)
                                    ])
                    ]
        Data.Security.UserMod name options ->
            object
                [ ("params", object [ ("name", string name)
                                    , ("options", dict identity string options)
                                    ])
                ]
        Data.Security.UserDel name ->
            object
                [ ("params", object [ ("name", string name) ]) ]

        Data.Security.AddUserGroups u gg ->
            object
                [ ("params", object [ ("user", string u)
                                    , ("groups", list string gg)
                                    ])
                ]
        Data.Security.DeleteUserGroups u gg ->
            object
                [ ("params", object [ ("user", string u)
                                    , ("groups", list string gg)
                                    ])
                ]

        Data.Security.AddUserPermissions u aa ->
            object
                [ ("params", object [ ("user", string u)
                                    , ("permissions", list string aa)
                                    ])
                ]
        Data.Security.DeleteUserPermissions u aa ->
            object
                [ ("params", object [ ("user", string u)
                                    , ("permissions", list string aa)
                                    ])
                ]

        Data.Security.ListGroups ->
            object
                [ ("params", object []) ]
        Data.Security.GroupAdd name options ->
            object
                [ ("params", object [ ("name", string name)
                                    , ("options", dict identity string options)
                                    ])
                ]
        Data.Security.GroupMod name options ->
            object
                [ ("params", object [ ("name", string name)
                                    , ("options", dict identity string options)
                                    ])
                ]
        Data.Security.GroupDel name ->
            object
                [ ("params", object [ ("name", string name) ]) ]

        Data.Security.AddGroupPermissions u aa ->
            object
                [ ("params", object [ ("group", string u)
                                    , ("permissions", list string aa)
                                    ])
                ]
        Data.Security.DeleteGroupPermissions u aa ->
            object
                [ ("params", object [ ("group", string u)
                                    , ("permissions", list string aa)
                                    ])
                ]

        Data.Security.ListPermissions ->
            object
                [ ("params", object []) ]
