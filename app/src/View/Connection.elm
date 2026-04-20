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
        [ versionInfoDetails m
        ]

versionInfoDetails m =
    div []
        [ versionInfoDetailsContent m
        , versionInfoDetailsActions
        ]

versionInfoDetailsContent m =
    div View.Style.cardInnerContent
        [ text
              ("Connected to: " ++ m.c.riakAdminCtlUrl ++ " (" ++ m.s.versionInfo.nodename ++ ")\n" ++
               "Riak version: " ++ m.s.versionInfo.riakVersion ++ " on " ++ m.s.versionInfo.systemVersion ++"\n" ++
               "      Uptime: " ++ m.s.versionInfo.uptimeStr)
        ]

versionInfoDetailsActions =
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
                                |> TextField.setLabel (Just "Riak node standard http listener URL")
                                |> TextField.setValue (Just m.s.newConfigRiakNodePingUrl)
                                |> TextField.setOnInput ConfigRiakNodePingUrlChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                |> TextField.setLabel (Just "Riak node Admin API (/ctl) URL")
                                |> TextField.setValue (Just m.s.newConfigRiakAdminCtlUrl)
                                |> TextField.setOnInput ConfigRiakAdminCtlUrlChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                |> TextField.setLabel (Just "Admin user")
                                |> TextField.setValue (Just m.s.newConfigRiakAdminCtlUser)
                                |> TextField.setOnInput ConfigRiakAdminCtlUserChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                |> TextField.setLabel (Just "Root password")
                                |> TextField.setValue (Just m.s.newConfigRiakAdminCtlPassword)
                                |> TextField.setOnInput ConfigRiakAdminCtlPasswordChanged
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
