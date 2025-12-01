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

module View.Boot exposing (makeContent)

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.Boot
import View.Style

import Html exposing (Html, text, div, pre)
import Html.Attributes exposing (attribute, style, class)
import Material.Button as Button
import Material.Dialog as Dialog
import Material.TextField as TextField
import Material.Typography as Typography


makeContent m =
    div View.Style.topContent
        [ maybeMakeAddKeyDialog m
        , maybeMakeDeleteKeyDialog m
        , makeScriptTemplateWithParams m
        ]

makeBootOption m =
    div [ style "flex-flow" "column nowrap" ]
        [ div [ style "flex-flow" "row nowrap"]
              [ TextField.filled
                    (TextField.config
                    |> TextField.setLabel (Just "Key name")
                    |> TextField.setValue (Just m.s.sshSelectedKeyId)
                    |> TextArea.setOnInput SshSelectedKeyIdChanged
                    )
              , TextField.filled
                    (TextField.config
                    |> TextField.setLabel (Just "Key")
                    |> TextField.setValue (Just m.s.sshSelectedKeyBody)
                    |> TextArea.setOnInput SshSelectedKeyIdChanged
                    )
              , Button.text
                    (Button.config |> Button.setOnClick StoreSshKey)
                    "Store"
              , Button.text
                    (Button.config |> Button.setOnClick DeleteSshKey)
                    "Delete"

              ]
        , TextField.filled
              (TextField.config
              |> TextField.setLabel (Just "Key name")
              |> TextField.setValue (Just m.s.sshSelectedKeyId)
              |> TextArea.setOnInput SshSelectedKeyIdChanged
              )
        , Button.text
              (Button.config |> Button.setOnClick SshExecScript)
              "Execute"
        ]
