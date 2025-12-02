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


makeContent m =
    div View.Style.topContent
        ([ makeScriptTemplateWithParams m
         , makeStoredKeysPart m
         ] ++ (maybeMakeAddKeyDialog m)
           ++ (maybeMakeDeleteKeyDialog m))

makeScriptTemplateWithParams m =
    let
        (k0, kk) =
            case m.s.sshStoredKeys of
                x0 :: xx -> (x0, xx)
                [] -> (Data.SshOps.dummySshKey, [])
        (t0, tt) =
            case m.s.sshScriptTemplateSpecs of
                x0 :: xx -> (x0, xx)
                [] -> (Data.SshOps.dummyScriptTemplate, [])
    in
        div [ style "flex-flow" "column nowrap" ]
            [ div [ style "flex-flow" "row nowrap"]
                  [ TextField.filled
                        (TextField.config
                        |> TextField.setLabel (Just "Target hosts")
                        |> TextField.setValue (Just (String.join ", " m.s.sshTargetHostList))
                        |> TextField.setOnInput SshTargetHostListChanged
                        )
                  , TextField.filled
                        (TextField.config
                        |> TextField.setLabel (Just "User")
                        |> TextField.setValue (Just m.s.sshTargetHostList)
                        |> TextField.setOnInput SshSelectedUserForExecChanged
                        )
                  , Select.outlined
                        (Select.config
                        |> Select.setLabel (Just "SSH key")
                        |> Select.setSelected (Just m.s.sshSelectedKeyName)
                        |> Select.setOnChange SshSelectedKeyNameForExecChanged
                        )
                        (SelectItem.selectItem (SelectItem.config { value = k0.name }) k0.name)
                        (List.map
                             (\{name} -> SelectItem.selectItem (SelectItem.config {value = name}) name)
                             kk)
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
                  ] ++ (makeScriptTemplateParams m)
            , Button.text
                  (Button.config |> Button.setOnClick SshExecScript)
              "Execute"
            ]

makeScriptTemplateParams m =
    let
        t = Model.scriptTemplateBy m name m.s.sshSelectedScriptTemplateName
        f =
            \(n, v) ->
                TextField.filled
                    (TextField.config
                    |> TextField.setLabel (Just n)
                    |> TextField.setValue (Just v)
                    |> TextField.setOnInput (SshScriptTemplateParamChanged n)
                    )
    in
        div [] (List.map f t.params)

makeStoredKeysPart m =
    div [] []
