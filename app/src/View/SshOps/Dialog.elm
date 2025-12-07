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

module View.SshOps.Dialog exposing
    ( maybeMakeAddKeyDialog
    , maybeMakeDeleteKeyDialog
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.SshOps
import View.Shared
import View.Style
import Util

import Html exposing (text, div)
import Html.Attributes exposing (attribute, style)
import Material.Button as Button
import Material.TextField as TextField
import Material.TextArea as TextArea
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.Dialog as Dialog

maybeMakeAddKeyDialog m =
    if m.s.sshAddKeyDialogShown then
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose SshAddKeyDialogCancelled
              )
              { title = "New ssh key"
              , content =
                    [ div View.Style.dialogContentPart
                          [ div [ style "display" "grid"
                                , style "grid-template-columns" "repeat(2, 1fr)"
                                , style "align-items" "left"
                                , style "margin" "0.6em 0 0 0"
                                ]
                                [ TextField.filled
                                      (TextField.config
                                      |> TextField.setLabel (Just "Name")
                                      |> TextField.setRequired True
                                      |> TextField.setOnChange SshNewKeyNameChanged
                                      |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                      )
                                , TextArea.filled
                                      (TextArea.config
                                      |> TextArea.setLabel (Just "Key")
                                      |> TextArea.setOnChange SshNewKeyBodyChanged
                                      |> TextArea.setAttributes [ attribute "spellCheck" "false" ]
                                      |> TextArea.setRows (Just 10)
                                      |> TextArea.setCols (Just 80)
                                      )
                                ]
                          ]
                    ]
              , actions =
                    [ Button.text
                          (Button.config |> Button.setOnClick SshAddKeyDialogCancelled)
                          "Cancel"
                    , Button.text
                          (Button.config
                          |> Button.setOnClick SshAddKeyDialogConfirmed
                          |> Button.setAttributes [ Dialog.defaultAction ]
                          )
                          "Ok"
                    ]
              }
        ]
    else
        []

maybeMakeDeleteKeyDialog m =
    if m.s.sshDeleteKeyDialogShown then
        let
            (n0, nn) =
                case m.s.sshStoredKeys of
                    x0 :: xx -> (x0, xx)
                    [] -> (Data.SshOps.dummySshKey, [])
        in
            [ Dialog.confirmation
                  (Dialog.config
                  |> Dialog.setOpen True
                  |> Dialog.setOnClose SshDeleteKeyDialogCancelled
                  )
                  { title = "Delete a ssh key"
                  , content =
                        [ Select.outlined
                              (Select.config
                              |> Select.setLabel Nothing
                              |> Select.setSelected (Just m.s.sshKeyNameToDelete)
                              |> Select.setOnChange SshKeyNameForDeletionChanged
                              )
                              (SelectItem.selectItem (SelectItem.config { value = n0.name }) n0.name)
                              (List.map
                                   (\{name} -> SelectItem.selectItem (SelectItem.config {value = name}) name)
                                   nn)
                        ]
                  , actions =
                        [ Button.text
                              (Button.config |> Button.setOnClick SshDeleteKeyDialogCancelled)
                              "Cancel"
                        , Button.text
                              (Button.config
                              |> Button.setOnClick SshDeleteKeyDialogConfirmed
                              |> Button.setAttributes [ Dialog.defaultAction ]
                              )
                          "Ok"
                    ]
              }
        ]
    else
        []

