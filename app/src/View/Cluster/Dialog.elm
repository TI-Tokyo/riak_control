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

module View.Cluster.Dialog exposing
    ( maybeMakeAddNodeDialog
    , maybeMakeReplacementDialog
    , maybeMakeNodeConfigDialog
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.Cluster
import View.Common exposing (SortByField(..))
import View.Shared
import View.Style
import Util

import Html exposing (Html, text, div, img, pre)
import Html.Attributes exposing (attribute, style, src)
import Material.Button as Button
import Material.TextField as TextField
import Material.TextArea as TextArea
import Material.Dialog as Dialog
import Material.Typography as Typography
import Material.Checkbox as Checkbox
import Material.FormField as FormField
import Dict

maybeMakeReplacementDialog m =
    case (m.s.replaceDialogShownFor, m.s.forceReplaceDialogShownFor) of
        ("", "") -> div [] []
        (a, "") ->
            div []
                (makeReplacementDialog
                     m ("Replace node " ++ a)
                     PlanNodeReplaceDialogConfirmed
                     PlanNodeReplaceDialogCancelled)
        ("", a) ->
            div []
                (makeReplacementDialog
                     m ("Force replace node " ++ a)
                     PlanNodeForceReplaceDialogConfirmed
                     PlanNodeForceReplaceDialogCancelled)
        (_, _) -> div [] []

makeReplacementDialog m a m1 m2 =
    [ Dialog.confirmation
          (Dialog.config |> Dialog.setOpen True |> Dialog.setOnClose m2)
          { title = a
          , content = [ TextField.filled
                            (TextField.config
                            |> TextField.setLabel (Just "With")
                            |> TextField.setRequired True
                            |> TextField.setValue (Just m.s.replaceNodeWith)
                            |> TextField.setOnInput PlanNodeReplaceWithChanged
                            |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                            )
                      ]
                  , actions =
                        [ Button.text
                              (Button.config
                              |> Button.setOnClick m2
                              ) "Cancel"
                        , Button.text
                              (Button.config
                              |> Button.setOnClick m1
                              |> Button.setAttributes [ Dialog.defaultAction ]
                              ) "Ok"
                        ]
          }
    ]



maybeMakeAddNodeDialog m =
    if m.s.addNodeDialogShown then
        div []
            [ Dialog.confirmation
                  (Dialog.config
                  |> Dialog.setOpen True
                  |> Dialog.setOnClose AddNodeDialogCancelled
                  )
                  { title = "Add node to cluster"
                  , content =
                        [ div [ style "display" "grid"
                              , style "grid-template-columns" "1"
                              , style "row-gap" "0.3em"
                              ]
                              [ TextField.filled
                                    (TextField.config
                                    |> TextField.setLabel (Just "Node to join")
                                    |> TextField.setValue (Just m.s.newNodeToJoin)
                                    |> TextField.setOnInput NewClusterNodeChanged
                                    |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                    )
                              ]
                        ]
                  , actions =
                        [ Button.text
                              (Button.config |> Button.setOnClick AddNodeDialogCancelled)
                              "Cancel"
                        , Button.text
                              (Button.config
                              |> Button.setOnClick PlanNodeJoin
                              |> Button.setAttributes [ Dialog.defaultAction ]
                              )
                              "Add"
                        ]
                  }
            ]
    else
        div [] []



maybeMakeNodeConfigDialog m =
    case m.s.nodeConfigShownFor of
        Nothing -> div [] []
        Just a ->
            div [ style "width" "max(max-content, 80%)"
                , style "max-height" "60%"
                ]
                [ Dialog.confirmation
                      (Dialog.config |> Dialog.setOpen True |> Dialog.setOnClose NodeConfigDialogCancelled)
                      { title = "Application environments on node " ++ a
                      , content = [ TextArea.filled
                                        (TextArea.config
                                        |> TextArea.setValue (Dict.get a m.s.nodeConfigs)
                                        |> TextArea.setRows (Just 20)
                                        |> TextArea.setCols (Just 90)
                                        |> TextArea.setOnInput NodeConfigChanged
                                        |> TextArea.setAttributes [ attribute "spellCheck" "false"
                                                                  , style "font-size" "small"
                                                                  , style "font-family" "monospace"
                                                                  , style "white-space" "pre"
                                                                  ]
                                        )
                                  ,  FormField.formField
                                        (FormField.config
                                        |> FormField.setLabel (Just "Persist to advanced.config?")
                                        )
                                        [ Checkbox.checkbox
                                              (Checkbox.config
                                              |> Checkbox.setState (checkBoxStateFromBool m.s.nodeConfigMakePersist)
                                              |> Checkbox.setOnChange PersistNodeConfigChanged
                                              )
                                        ]
                                  ]
                      , actions =
                            [ Button.text
                                  (Button.config
                                  |> Button.setOnClick NodeConfigDialogCancelled
                                  ) "Cancel"
                            , Button.text
                                  (Button.config
                                  |> Button.setOnClick NodeConfigDialogConfirmed
                                  |> Button.setAttributes [ Dialog.defaultAction ]
                                  ) "Apply"
                            ]
                      }
                ]



checkBoxStateFromBool a =
    if a then
        Just Checkbox.checked
    else
        Just Checkbox.unchecked
