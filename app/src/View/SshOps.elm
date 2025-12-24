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

module View.SshOps exposing (makeContent)

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.SshOps
import View.Style
import View.SshOps.Dialog exposing (..)

import Html exposing (Html, text, div, pre)
import Html.Attributes exposing (attribute, style, class)
import Material.Button as Button
import Material.TextField as TextField
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.Typography as Typography
import RemoteData

makeContent m =
    div View.Style.topContent
        ([ makeMain m
         ] ++ (maybeMakeAddKeyDialog m)
           ++ (maybeMakeDeleteKeyDialog m))

makeMain m =
    div [ style "flex-direction" "column"
        , style "padding" "2em 1em 2em"
        ] [ makeSshKeysBlock m
          , makeScriptTemplateBlock m
          ]

makeSshKeysBlock m =
    let
        kk = String.join ", " <| List.map .name m.s.sshStoredKeys
        ntotal = List.length m.s.sshStoredKeys
    in
        div [ style "display" "grid", style "grid-template-columns" "auto min-content min-content"
            ] [ text <| "Keys available on server (" ++ (String.fromInt ntotal) ++ "): " ++ kk
              , Button.text (Button.config |> Button.setOnClick ShowAddSshKeyDialog) "Add"
              , Button.text (Button.config |> Button.setOnClick ShowDeleteSshKeyDialog) "Remove"
              ]

makeScriptTemplateBlock m =
    if m.s.sshScriptExecuting then
        makeScriptTemplateBlockExecuting m
    else
        makeScriptTemplateBlockWaiting m

makeScriptTemplateBlockWaiting m =
    let
        (t0, tt) =
            case m.s.sshScriptTemplateSpecs of
                x0 :: xx -> (x0, xx)
                [] -> (Data.SshOps.dummyScriptTemplate, [])
    in
        div [ style "flex-direction" "rows" ]
            [ div [ style "display" "grid"
                  , style "grid-template-columns" "30em auto"
                  ] [ TextField.filled
                          (TextField.config
                          |> TextField.setLabel (Just "Target hosts")
                          |> TextField.setValue (Just m.s.sshTargetHostsStr)
                          |> TextField.setOnInput SshTargetHostsChanged
                          )
                    , Select.outlined
                          (Select.config
                          |> Select.setLabel (Just "Script")
                          |> Select.setSelected (Just m.s.sshSelectedScriptTemplateName)
                          |> Select.setOnChange SshSelectedScriptTemplateNameForExecChanged
                          )
                          (SelectItem.selectItem (SelectItem.config { value = t0.name }) t0.name)
                          (List.map
                               (\{name} -> SelectItem.selectItem (SelectItem.config {value = name}) name)
                               tt)
                    ]
            , makeScriptTemplateParams m
            , Button.text
                  (Button.config
                  |> Button.setOnClick ExecSshScript
                  |> Button.setDisabled (not (goodToExec m))
                  ) "Execute"
            ]

goodToExec m =
    m.s.sshTargetHostsStr /= ""


makeScriptTemplateParams m =
    let
        pp = Model.scriptTemplateBy m .name m.s.sshSelectedScriptTemplateName |> .params
        f =
            \{name, value, description} ->
                [ div [ style "text-align" "end"
                      , style "align-self" "center"
                      , style "font-size" "large"
                      , style "padding-right" "1em"
                      , style "font-family" "monospace"
                      ] [ text name ]
                , TextField.filled
                      (TextField.config
                      |> TextField.setLabel Nothing
                      |> TextField.setValue (Just value)
                      |> TextField.setOnInput (SshScriptTemplateParamChanged name)
                      )
                , div [ style "grid-column-end" "span 2"
                      , style "padding-bottom" "2em"
                      , style "font-size" "small"
                      , style "color" "#454545"
                      ] [ text description ]
                ]
    in
        if pp /= [] then
            div []
                [ div [ style "font-weight" "bold" ] [ text "Script parameters:" ]
                , div [ style "display" "grid"
                      , style "grid-template-columns" "auto 1fr"
                      ] (List.map f pp |> List.concat)
                ]
        else
            div [] []


makeScriptTemplateBlockExecuting m =
    let
        output =
            case m.s.sshScriptOutput of
                RemoteData.NotAsked -> ""
                RemoteData.Loading -> "(waiting)"
                RemoteData.Success s -> s
                RemoteData.Failure e -> "failed"
    in
        div [ style "flex-direction" "rows" ]
            [ div [ style "white-space" "pre"
                  , style "font-family" "monospace"
                  ] [ text output ]
            , Button.text
                  (Button.config
                  |> Button.setOnClick ExecSshScriptDone
                  |> Button.setDisabled (not (goodToExec m))
                  ) "Finish"
        ]
