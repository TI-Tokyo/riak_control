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

module View.General exposing (makeContent)

import Model exposing (Model)
import Msg exposing (Msg(..))
import View.Common
import View.Shared
import View.Style
import Util

import Html exposing (Html, text, div, pre)
import Html.Attributes exposing (attribute, style)
import Material.Card as Card
import Material.Button as Button
import Material.Dialog as Dialog
import Material.TextField as TextField
import Material.Typography as Typography

makeContent m =
    Html.div View.Style.topContent
        [ div [] [ makeServerInfo m ]
        , div [] (makeServerConfigDialog m)
        , div [style "width" "max(max-content, 80%)"] (configDialog m)
        ]

makeServerInfo m =
    Html.div [ style "align-content" "center"
             ]
        [ Html.div [ style "width" "min-content" ]
              [ serverInfoDetails m ]
        ]

serverInfoDetails m =
    Card.card Card.config
        { blocks =
              ( Card.block <|
                    div View.Style.cardInnerHeader
                        [ text "RDrive instance" ]
              , [ Card.block <|
                    div View.Style.cardInnerContent
                        [ text (cardContent m) ]
                ]
              )
        , actions = cardActions
        }

makeServerConfigDialog m =
    if m.s.serverConfigShown then
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose ServerConfigDialogDismissed
              |> Dialog.setAttributes [ style "max-height" "80%"
                                      , style "z-index" "90"
                                      ]
              )
              { title = "RDrive server config"
              , content = [ div [ style "font-size" "small"
                                , style "font-family" "monospace"
                                , style "white-space" "pre"
                                ]
                                [ text (Util.pprintJson m.s.serverInfo.configRaw) ]
                          ]
              , actions = [ Button.text (Button.config
                                        |> Button.setOnClick ServerConfigDialogDismissed)
                                "Dismiss"
                          ]
              }
        ]
    else
        []

cardContent m =
    "Riak instance url: " ++ m.c.riakUrl ++ "\n" ++
    "     Riak version: " ++ m.s.serverInfo.version.rdrive ++ " on " ++ m.s.serverInfo.version.otp ++"\n" ++
    "           Uptime: " ++ m.s.serverInfo.uptime.uptime

cardActions =
    Just <|
        Card.actions
            { buttons =
                  [ Card.button (Button.config
                                |> Button.setOnClick ShowConfigDialog
                                ) "Change"
                  , Card.button (Button.config
                                |> (Button.setOnClick ShowServerConfig))
                        "Show Server Config"
                  ]
            , icons =
                []
            }


configDialog m =
    if m.s.configDialogShown then
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose SetConfigCancelled
              )
              { title = "RDrive instance url and admin creds"
              , content =
                    [ Html.div [ style "display" "grid"
                               , style "grid-template-columns" "1"
                               , style "row-gap" "0.3em"
                               ]
                          [ TextField.filled
                                (TextField.config
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                |> TextField.setLabel (Just "Riak node url")
                                |> TextField.setValue (Just m.s.newConfigUrl)
                                |> TextField.setOnInput ConfigUrlChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                |> TextField.setLabel (Just "Root password")
                                |> TextField.setValue (Just m.s.newConfigRootPassword)
                                |> TextField.setOnInput ConfigRootPasswordChanged
                                )
                          , TextField.filled
                                (TextField.config
                                |> TextField.setAttributes [ attribute "spellCheck" "false" ]
                                |> TextField.setLabel (Just "Admin path prefix")
                                |> TextField.setValue (Just m.s.newConfigAdminPathPrefix)
                                |> TextField.setOnInput ConfigAdminPathPrefixChanged
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
