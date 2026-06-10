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

module View.User.Dialog exposing
    ( makeCreateUserDialog
    , makeEditUserDialog
    , makeEditUserGroupsDialog
    , makeAddUserGroupsDialog
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.Security
import Data.Security.Lib as Lib
import View.Common exposing (SortByField(..))
import View.Shared
import View.Style
import Util

import Html exposing (text, div)
import Html.Attributes exposing (attribute, style)
import Material.Button as Button
import Material.IconButton as IconButton
import Material.TextField as TextField
import Material.TextArea as TextArea
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.Switch as Switch
import Material.Checkbox as Checkbox
import Material.Chip.Filter as FilterChip
import Material.ChipSet.Filter as FilterChipSet
import Material.Dialog as Dialog
import Json.Decode as JD
import Time


makeCreateUserDialog m =
    if m.s.createUserDialogShown then
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose CreateUserCancelled
              )
              { title = "New user"
              , content =
                    [ div View.Style.newUserDialogGrid
                           [ TextField.filled
                                 (TextField.config
                                 |> TextField.setLabel (Just "Name")
                                 |> TextField.setRequired True
                                 |> TextField.setOnChange NewUserNameChanged
                                 |> TextField.setAttributes innerAttrs
                                 )
                           , TextField.filled
                                 (TextField.config
                                 |> TextField.setLabel (Just "Password")
                                 |> TextField.setRequired True
                                 |> TextField.setPlaceholder (Just "At least 8 chars")
                                 |> TextField.setOnChange NewUserPasswordChanged
                                 |> TextField.setAttributes innerAttrs
                                 )
                           , TextField.filled
                                 (TextField.config
                                 |> TextField.setLabel (Just "Expires in")
                                 |> TextField.setRequired True
                                 |> TextField.setPlaceholder (Just "\"2026-03-18T01:02:03\". \"in 5d 6h\" or \"never\"")
                                 |> TextField.setOnChange NewUserExpiresChanged
                                 |> TextField.setAttributes innerAttrs2
                                 )
                           , TextArea.outlined
                                 (TextArea.config
                                 |> TextArea.setLabel (tagsLabel m)
                                 |> TextArea.setOnInput NewUserTagsChanged
                                 |> TextArea.setRows (Just 12)
                                 |> TextArea.setCols (Just 44)
                                 |> TextArea.setAttributes innerAttrs2
                                 )
                           ]
                    ]
              , actions =
                    [ Button.text
                          (Button.config |> Button.setOnClick CreateUserCancelled)
                          "Cancel"
                    , Button.text
                          (Button.config
                          |> Button.setOnClick CalculateNewUserExpiryAndCreateUser
                          |> Button.setDisabled (not (allRequiredFieldsGood m))
                          |> Button.setAttributes [ Dialog.defaultAction ]
                          )
                          "Create"
                    ]
              }
        ]
    else
        []

allRequiredFieldsGood m =
    (m.s.newUserName /= "")
    && (isGoodPassword m.s.newUserPassword)
    && (isGoodExpires m.s.newUserExpires)
    && (m.s.newUserTags == "" || isGoodTags m.s.newUserTags)

isGoodPassword a =
    7 < String.length a

isGoodExpires a =
    case Lib.convertExpires a (Time.millisToPosix 0) of
        Ok _ -> True
        Err _ -> False

isGoodTags a =
    case JD.decodeString (JD.dict JD.string) a of
        Ok _ -> True
        Err _ -> False

makeEditUserDialog m =
    case m.s.openEditUserDialogFor of
        Just a ->
            makeEditUserDialog2 m (Model.userBy m .name a)
        Nothing ->
            []
makeEditUserDialog2 m u =
    [ Dialog.confirmation
          (Dialog.config
          |> Dialog.setOpen True
          |> Dialog.setOnClose EditUserCancelled
          )
          { title = "Edit user " ++ u.name
          , content =
                [ div View.Style.dialogContentPart
                      [ div View.Style.newUserDialogGrid
                            [ TextField.filled
                                  (TextField.config
                                  |> TextField.setLabel (Just "Expires in")
                                  |> TextField.setRequired True
                                  |> TextField.setValue (Just m.s.editedUserExpires)
                                  |> TextField.setPlaceholder (Just "\"2026-03-18T01:02:03\". \"in 5d 6h\" or \"never\"")
                                  |> TextField.setOnChange EditedUserExpiresChanged
                                  |> TextField.setAttributes innerAttrs2
                                  )
                            , TextArea.outlined
                                  (TextArea.config
                                  |> TextArea.setLabel (tagsLabel m)
                                  |> TextArea.setValue (Just m.s.editedUserTags)
                                  |> TextArea.setOnInput EditedUserTagsChanged
                                  |> TextArea.setRows (Just 12)
                                  |> TextArea.setCols (Just 44)
                                  |> TextArea.setAttributes innerAttrs2
                                  )
                            ]
                      ]
                ]
          , actions =
                [ Button.text
                      (Button.config |> Button.setOnClick EditUserCancelled)
                      "Cancel"
                , Button.text
                      (Button.config
                      |> Button.setOnClick CalculateEditedUserExpiryAndUpdateUser
                      |> Button.setAttributes [ Dialog.defaultAction ]
                  )
                  "Update"
                ]
          }
    ]


makeEditUserGroupsDialog m =
    case m.s.openEditUserGroupsDialogFor of
        Just a ->
            makeEditUserGroupsDialog2 m a
        Nothing ->
            []
makeEditUserGroupsDialog2 m a =
    let u = Model.userBy m .name a in
    [ Dialog.confirmation
          (Dialog.config
          |> Dialog.setOpen True
          |> Dialog.setOnClose EditUserGroupsCancelled
          )
          { title = "User groups"
          , content =
                [ div View.Style.dialogContentPart
                      ([ View.Shared.groupsAsList m
                             u.groups
                             m.s.selectedUserGroupsForDelete
                             SelectOrUnselectUserGroupToDelete ]
                           ++ [ div []
                                    [ IconButton.iconButton
                                         (IconButton.config
                                         |> IconButton.setOnClick (ShowAddUserGroupDialog a))
                                         (IconButton.icon "add")
                                    ,  IconButton.iconButton
                                          (IconButton.config
                                          |> IconButton.setOnClick DeleteUserGroupBatch
                                          |> IconButton.setDisabled (m.s.selectedUserGroupsForDelete == [])
                                          |> IconButton.setAttributes [ style "color" "red" ])
                                          (IconButton.icon "delete")
                                    ]
                              ]
                      )
                ]
          , actions =
                [ Button.text
                      (Button.config |> Button.setOnClick EditUserGroupsCancelled)
                      "Dismiss"
                ]
          }
    ]


makeAddUserGroupsDialog m =
    case m.s.openAddUserGroupsDialogFor of
        Just a ->
            makeAddUserGroupsDialog2 m a
        Nothing ->
            []

makeAddUserGroupsDialog2 m a =
    let
        u = Model.userBy m .name a
        allGroups = List.map .name m.s.groups
    in
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose AddUserGroupDialogCancelled
              )
              { title = "Available groups"
              , content =
                    [ div View.Style.dialogContentPart
                          [ View.Shared.groupsAsList m
                                (Util.subtract allGroups u.groups)
                                m.s.selectedUserGroupsForAdd
                                SelectOrUnselectUserGroupToAdd ]
                    ]
              , actions =
                    [ Button.text
                          (Button.config |> Button.setOnClick AddUserGroupDialogCancelled)
                          "Dismiss"
                    , Button.text
                          (Button.config
                          |> Button.setOnClick AddUserGroupBatch
                          |> Button.setDisabled (m.s.selectedUserGroupsForAdd == [])
                          |> Button.setAttributes [ Dialog.defaultAction ])
                          "Add"
                    ]
              }
        ]


innerAttrs =
    [ attribute "spellCheck" "false"
    , style "margin" ".4em 0 .4em"
    ]
innerAttrs2 =
    innerAttrs ++
        [ style "grid-column-end" "span 2" ]
tagsLabel m =
    if m.s.newUserTags == "" then
        (Just "Tags (as a JSON object")
    else Nothing
