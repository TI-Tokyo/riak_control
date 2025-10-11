-- ---------------------------------------------------------------------
--
-- Copyright (c) 2024 TI Tokyo    All Rights Reserved.
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

module View exposing (view)

import View.General
import View.Cluster
import View.Cluster.AppBarContent
import View.Ttaae
import View.Ttaae.AppBarContent
import View.Vnode
import View.Vnode.AppBarContent
import View.User
import View.User.AppBarContent
import View.Group
import View.Group.AppBarContent
import View.Style
import Model exposing (Model)
import Msg exposing (Msg(..))

import Html exposing (Html, text, div, img, span)
import Html.Attributes exposing (style, attribute, src)
import Material.Drawer.Dismissible as DismissibleDrawer
import Material.TopAppBar as TopAppBar
import Material.Snackbar as Snackbar
import Material.Button as Button
import Material.IconButton as IconButton
import Material.List as List
import Material.List.Item as ListItem
import Material.Typography as Typography


view : Model -> Html Msg
view m =
    div [ Typography.typography ]
        [ div [] [makeTopAppBar m]
        , div [TopAppBar.fixedAdjust] [makeDrawer m]
        , Snackbar.snackbar
              (Snackbar.config { onClosed = SnackbarClosed })
                  m.s.msgQueue
        ]


makeTopAppBar m =
    TopAppBar.regular
        (TopAppBar.config
        |> TopAppBar.setFixed True
        |> TopAppBar.setAttributes [ style "z-index" "20"
                                   , style "background" "#64a8da" ])
        [ TopAppBar.row []
              [ TopAppBar.section [ TopAppBar.alignStart ]
                    [ IconButton.iconButton
                          (IconButton.config
                          |> IconButton.setOnClick OpenTopDrawer
                          |> IconButton.setAttributes
                               [ TopAppBar.navigationIcon ])
                          (IconButton.icon "menu")
                    , IconButton.iconButton
                          (IconButton.config
                          |> IconButton.setOnClick (listWhat m)
                          )
                          (IconButton.icon "refresh")
                    , text (activeTabName m)
                    ]
              , TopAppBar.section [ TopAppBar.alignStart ]
                  [ makeFilterControls m ]
              , TopAppBar.section [ TopAppBar.alignEnd ]
                  [ span [ TopAppBar.alignEnd, style "padding" "0 1em" ]
                        [ text m.c.riakNodeUrl ]
                  , span [ TopAppBar.alignEnd ]
                      [ img [src "images/openriak-logo.png", style "object-fit" "contain"] [] ]
                  ]
              ]
        ]


listWhat m =
    case m.s.activeTab of
        Msg.General -> GetServerInfo
        Msg.Cluster -> GetCluster
        Msg.Ttaae -> GetTtaaeReport
        Msg.Vnode -> GetVnodeStatus
        Msg.Users -> ListUsers
        Msg.Groups -> ListGroups


makeDrawer m =
    div
        [ style "display" "flex"
        , style "flex-flow" "row nowrap"
        ]
        [ DismissibleDrawer.drawer
              (DismissibleDrawer.config
              |> DismissibleDrawer.setOpen m.s.topDrawerOpen
              )
              [ DismissibleDrawer.content []
                    [ List.list List.config
                          ( ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.General)
                                )
                                [ text "General" ]
                          )
                          [ ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.Cluster)
                                )
                                [ itemWithCount "Cluster" m.s.cluster.current ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.Vnode)
                                )
                                [ text "Vnode" ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.Ttaae)
                                )
                                [ text "TictacAAE" ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.Users)
                                )
                                [ itemWithCount "Users" m.s.users ]
                          , ListItem.listItem
                                (ListItem.config
                                |> ListItem.setOnClick (TabClicked Msg.Groups)
                                )
                                [ itemWithCount "Groups" m.s.groups ]
                          ]
                    ]
              ]
        , div [ DismissibleDrawer.appContent ]
            [ makeContents m ]
        ]

itemWithCount s a =
     s ++ " (" ++ (List.length a |> String.fromInt) ++ ")" |> text

makeContents m =
    case m.s.activeTab of
        Msg.General -> View.General.makeContent m
        Msg.Cluster -> View.Cluster.makeContent m
        Msg.Ttaae -> View.Ttaae.makeContent m
        Msg.Vnode -> View.Vnode.makeContent m
        Msg.Users -> View.User.makeContent m
        Msg.Groups -> View.Group.makeContent m

makeFilterControls m =
    case m.s.activeTab of
        Msg.General -> div [] []
        Msg.Cluster -> div View.Style.filterAndSort (View.Cluster.AppBarContent.makeFilterControls m)
        Msg.Ttaae -> div View.Style.filterAndSort (View.Ttaae.AppBarContent.makeFilterControls m)
        Msg.Vnode -> div View.Style.filterAndSort (View.Vnode.AppBarContent.makeFilterControls m)
        Msg.Users -> div View.Style.filterAndSort (View.User.AppBarContent.makeFilterControls m)
        Msg.Groups -> div View.Style.filterAndSort (View.Group.AppBarContent.makeFilterControls m)

activeTabName m =
    case m.s.activeTab of
        Msg.General -> "General"
        Msg.Cluster -> "Cluster"
        Msg.Ttaae -> "TictacAAE"
        Msg.Vnode -> "Vnode"
        Msg.Users -> "Users"
        Msg.Groups -> "Groups"
