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

module View.Group.Dialog exposing
    ( makeEditGroupDialog
    , makeCreateGroupDialog
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.Security
import View.Common exposing (SortByField(..))
import View.Shared
import View.Style
import Util

import Html exposing (text, div)
import Html.Attributes exposing (attribute, style)
import Material.Button as Button
import Material.IconButton as IconButton
import Material.TextField as TextField
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.Switch as Switch
import Material.Checkbox as Checkbox
import Material.Chip.Filter as FilterChip
import Material.ChipSet.Filter as FilterChipSet
import Material.Dialog as Dialog

makeCreateGroupDialog m =
    if m.s.createGroupDialogShown then
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose CreateGroupCancelled
              )
              { title = "New group"
              , content =
                    [ div View.Style.dialogContentPart
                          [ div View.Style.newUserDialogGrid
                                [ TextField.filled
                                      (TextField.config
                                      |> TextField.setLabel (Just "Name")
                                      |> TextField.setRequired True
                                      |> TextField.setOnChange NewGroupNameChanged
                                      |> TextField.setAttributes [ attribute "spellCheck" "false"
                                                                 , style "grid-column-end" "span 2"
                                                                 ]
                                      )
                                ]
                          ]
                    ]
              , actions =
                    [ Button.text
                          (Button.config |> Button.setOnClick CreateGroupCancelled)
                          "Cancel"
                    , Button.text
                          (Button.config
                          |> Button.setOnClick CreateGroup
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
    (m.s.newGroupName /= "")



makeEditGroupDialog m =
    case m.s.openEditGroupDialogFor of
        Just g ->
            [ Dialog.confirmation
                  (Dialog.config
                  |> Dialog.setOpen True
                  |> Dialog.setOnClose EditGroupCancelled
                  )
                  { title = "Edit group " ++ g.name
                  , content =
                        [ div View.Style.dialogContentPart
                              [ div View.Style.newUserDialogGrid
                                  [ text "TODO: Tags"
                                  ]
                              ]
                        ]
                  , actions =
                        [ Button.text
                              (Button.config |> Button.setOnClick EditGroupCancelled)
                              "Cancel"
                        , Button.text
                              (Button.config
                              |> Button.setOnClick UpdateGroup
                              |> Button.setAttributes [ Dialog.defaultAction ]
                          )
                          "Update"
                        ]
                  }
            ]
        Nothing ->
            []
