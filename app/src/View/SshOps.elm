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

module View.SshOps exposing (makeContent)

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.SshOps
import View.Style
import View.Shared
import View.SshOps.Dialog exposing (..)
import Util

import Html exposing (Html, text, div, pre, b, code)
import Html.Attributes exposing (attribute, style, class)
import Material.Button as Button
import Material.TextField as TextField
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.Checkbox as Checkbox
import Material.FormField as FormField
import Material.Typography as Typography
import RemoteData

makeContent m =
    div View.Style.topContent
        ([ makeMain m
         ] ++ (maybeMakeEditAdminCredsDialog m)
           ++ (maybeMakeAddKeyDialog m)
           ++ (maybeMakeDeleteKeyDialog m))

makeMain m =
    div [ style "flex-direction" "column"
        , style "padding" "2em 1em 2em"
        ] [ makeRctlServerBlock m
          , makeSshKeysBlock m
          , div [ style "border-top" "solid grey"
                , style "padding" "1em 0 0"
                ] [ makeScriptBlock m ]
          ]

makeRctlServerBlock m =
    div [ style "display" "grid", style "grid-template-columns" "auto min-content"
        ] [ div [] [ text <| "Riak Control server at "
                   , b [] [ text m.c.riakControlServerUrl ]
                   , text <| ", admin user "
                   , b [] [ text m.c.riakControlServerUser ]
                   ]
          , Button.text (Button.config |> Button.setOnClick ShowRctlEditAdminCredsDialog) "Creds"
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

makeScriptBlock m =
    case m.s.sshScriptExecutionStatus of
        Data.SshOps.ScriptNotStarted -> makeScriptBlockWaiting m
        Data.SshOps.ScriptRunning -> makeScriptBlockExecuting m Data.SshOps.ScriptRunning
        Data.SshOps.ScriptFinished -> makeScriptBlockExecuting m Data.SshOps.ScriptFinished

makeScriptBlockWaiting m =
    let
        (t0, tt) =
            Util.headAndTail m.s.sshScriptTemplateSpecs Data.SshOps.dummyScriptTemplate
        selectedTemplate = Model.scriptTemplateBy m .name m.s.sshSelectedScriptTemplateName
    in
        div [ style "flex-direction" "rows" ]
            [ div [ style "display" "grid"
                  , style "grid-template-columns" "30em auto"
                  ] [ div [ style "grid-column-end" "span 2"
                          , style "padding-bottom" "0.5em"
                          , style "color" "grey"
                          ] [ text "Target host, following this pattern: "
                            , code [] [ text "user@host (key-name)" ]
                            , text " (key-name is optional, and is one of the keys added above)."
                            ]
                    , TextField.filled
                          (TextField.config
                          |> TextField.setLabel (Just "Target hosts")
                          |> TextField.setValue (Just m.s.sshTargetHostsStr)
                          |> TextField.setOnInput SshTargetHostsChanged
                          |> TextField.setAttributes [ attribute "spellCheck" "false" ]
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
                    , div [ style "padding-top" "1em"
                          , style "grid-column-end" "span 2"
                          ] [ text selectedTemplate.description ]
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
             |> List.filter (\{expert} -> not expert)
    in
        if pp /= [] then
            div []
                ([ div [ style "font-weight" "bold"
                       , style "padding-top" "2em"
                       ] [ text "Script parameters:" ]
                 , div [ style "display" "grid"
                       , style "grid-template-columns" "auto 1fr"
                       ] (List.map materialParam pp |> List.concat)
                 ] ++ (maybeExpertParamsSection m))
        else
            div [] []

maybeExpertParamsSection m =
    let
        pp = Model.scriptTemplateBy m .name m.s.sshSelectedScriptTemplateName |> .params
             |> List.filter .expert
        ppBlock =
            if m.s.sshScriptTemplateExpertParamsShown then
                [ div [ style "display" "grid"
                      , style "grid-template-columns" "auto 1fr"
                      ] (List.map materialParam pp |> List.concat)
                ]
            else
                []
    in
        if pp /= [] then
            [ div [ style "padding-top" "1em"
                  ] [ FormField.formField
                          (FormField.config
                          |> FormField.setLabel (Just "Expert parameters")
                          )
                          [ Checkbox.checkbox
                                (Checkbox.config
                                |> Checkbox.setState
                                     (View.Shared.checkboxStateFromBool
                                          m.s.sshScriptTemplateExpertParamsShown)
                                |> Checkbox.setOnChange SshScriptTemplateExpertToggle
                                )
                          ]
                    ]
            ] ++ ppBlock
        else
            []

materialParam {name, value, description} =
    [ div [ style "grid-column-end" "span 2"
          , style "padding-top" "2em"
          , style "color" "grey"
          ] [ text description ]
    , div [ style "text-align" "end"
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
    ]


makeScriptBlockExecuting m status =
    let
        b =
            if status == Data.SshOps.ScriptRunning then
                Button.text
                    (Button.config
                    |> Button.setOnClick ExecSshScriptInterrupt
                    ) "Interrupt"
            else
                Button.text
                    (Button.config
                    |> Button.setOnClick ExecSshScriptDone
                    ) "Finish"
    in
        div [ style "flex-direction" "rows" ]
            [ div [ style "white-space" "pre"
                  , style "background-color" "black"
                  , style "color" "white"
                  , style "padding" "1em"
                  , style "font-family" "monospace"
                  ] [ text m.s.sshScriptOutput ]
            , b
            ]
