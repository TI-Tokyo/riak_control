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

module View.User.Dialog exposing
    ( makeEditUserDialog
    , makeCreateUserDialog
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
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

makeCreateUserDialog m =
    if m.s.createUserDialogShown then
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose CreateUserCancelled
              )
              { title = "New user"
              , content =
                    [ div [ style "display" "grid"
                          , style "grid-template-columns" "1"
                          , style "row-gap" "0.3em"
                          ]
                          [ div [ style "display" "grid"
                                , style "grid-template-columns" "repeat(2, 1fr)"
                                , style "align-items" "left"
                                , style "margin" "0.6em 0 0 0"
                                ]
                                [ TextField.filled
                                      (TextField.config
                                      |> TextField.setLabel (Just "Name")
                                      |> TextField.setRequired True
                                      |> TextField.setOnChange NewUserNameChanged
                                      |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                      )
                                ]
                          ]
                    ]
              , actions =
                    [ Button.text
                          (Button.config |> Button.setOnClick CreateUserCancelled)
                          "Cancel"
                    , Button.text
                          (Button.config
                          |> Button.setOnClick CreateUser
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
    && (Util.isGoodPassword m.s.newUserPassword)



makeEditUserDialog m =
    case m.s.openEditUserDialogFor of
        Just u ->
            [ Dialog.confirmation
                  (Dialog.config
                  |> Dialog.setOpen True
                  |> Dialog.setOnClose EditUserCancelled
                  )
                  { title = "Edit user " ++ u.name
                  , content =
                        [ div [ style "display" "grid"
                                   , style "grid-template-columns" "1"
                                   , style "row-gap" "0.3em"
                                   ]
                              [ div [ style "display" "grid"
                                         , style "grid-template-columns" "repeat(2, 1fr)"
                                         , style "align-items" "center"
                                         , style "margin" "0.6em 0 0 0"
                                         ]
                                  [ text "Enabled"
                                  ]
                              ]
                        ]
                  , actions =
                        [ Button.text
                              (Button.config |> Button.setOnClick EditUserCancelled)
                              "Cancel"
                        , Button.text
                              (Button.config
                              |> Button.setOnClick UpdateUser
                              |> Button.setAttributes [ Dialog.defaultAction ]
                          )
                          "Update"
                        ]
                  }
            ]
        Nothing ->
            []
