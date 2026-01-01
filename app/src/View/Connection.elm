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

module View.Connection exposing (makeContent)

import Model exposing (Model)
import Msg exposing (Msg(..))
import View.Style

import Html exposing (Html, text, div, pre)
import Html.Attributes exposing (attribute, style)
import Material.Button as Button
import Material.Dialog as Dialog
import Material.TextField as TextField
import Material.Typography as Typography

makeContent m =
    div View.Style.topContent
        [ div [] [ makeServerInfo m ]
        , div [style "width" "max(max-content, 80%)"] (configDialog m)
        ]

makeServerInfo m =
    div []
        [ serverInfoDetails m
        ]

serverInfoDetails m =
    div []
        [ serverInfoDetailsContent m
        , serverInfoDetailsActions
        ]

serverInfoDetailsContent m =
    div View.Style.cardInnerContent
        [ text
              ("Connected to: " ++ m.c.riakNodeUrl ++ "\n" ++
               "Riak version: " ++ m.s.serverInfo.riakVersion ++ " on " ++ m.s.serverInfo.systemVersion ++"\n" ++
               "      Uptime: " ++ m.s.serverInfo.uptimeStr)
        ]

serverInfoDetailsActions =
    div []
        [ Button.text (Button.config |> Button.setOnClick ShowConfigDialog) "Change"
        , Button.text (Button.config |> Button.setOnClick Ping) "Ping"
        ]


configDialog m =
    if m.s.configDialogShown then
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose SetConfigCancelled
              )
              { title = "Riak node url and admin creds"
              , content =
                    [ div [ style "display" "grid"
                          , style "grid-template-columns" "1"
                          , style "row-gap" "0.3em"
                          ]
                          [ TextField.filled
                                (TextField.config
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                |> TextField.setLabel (Just "Riak node url")
                                |> TextField.setValue (Just m.s.newConfigRiakNodeUrl)
                                |> TextField.setOnInput ConfigRiakNodeUrlChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                |> TextField.setLabel (Just "Admin user")
                                |> TextField.setValue (Just m.s.newConfigRiakAdminUser)
                                |> TextField.setOnInput ConfigRiakAdminUserChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                |> TextField.setLabel (Just "Root password")
                                |> TextField.setValue (Just m.s.newConfigRiakAdminPassword)
                                |> TextField.setOnInput ConfigRiakAdminPasswordChanged
                                )
                          ]
                    ]
              , actions =
                    [ Button.text
                          (Button.config |> Button.setOnClick SetConfigCancelled)
                          "Cancel"
                    , Button.text
                          (Button.config
                          |> Button.setOnClick SetConfig
                          |> Button.setAttributes [ Dialog.defaultAction ]
                          )
                          "Ok"
                    ]
              }
        ]
    else
        []
