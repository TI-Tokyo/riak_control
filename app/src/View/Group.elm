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

module View.Group exposing
    ( makeContent
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.Security
import View.Group.Dialog
import View.Common exposing (SortByField(..))
import View.Shared
import View.Style
import Util

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (attribute, style, src)
import Material.Card as Card
import Material.Fab as Fab
import Material.Button as Button
import Material.IconButton as IconButton
import Material.TextField as TextField
import Material.Typography as Typography
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.Switch as Switch
import Iso8601
import Dict


makeContent m =
    div View.Style.topContent
        [ div View.Style.card (makeGroups m)
        , div [] (View.Group.Dialog.makeCreateGroupDialog m)
        , div [] (View.Group.Dialog.makeEditGroupDialog m)
        , div [] (View.Shared.makeEditPermissionsDialog m Data.Security.GroupClass)
        , div [] (View.Shared.makeAddPermissionsDialog m Data.Security.GroupClass)
        , div [] (View.Shared.makeDeleteThingConfirmDialog
                      m .confirmDeleteGroupDialogShownFor
                      (.name << (Model.groupBy m .name)) "group"
                      DeleteGroupConfirmed DeleteGroupNotConfirmed)
        , div [] (maybeShowCreateGroupFab m)
        ]


makeGroups m =
    case m.s.groups |> (filter m) |> (sort m) |> List.map (makeGroup m) of
        [] ->
            [ img [src "images/filter-man.jpg"] [] ]
        rr ->
            rr

filter m aa =
    case m.s.groupFilterValue of
        "" -> aa
        s ->
            List.filter
                (\g ->
                     (  (List.member "Name" m.s.groupFilterIn && String.contains s g.name)
                     )
                ) aa

sort m aa =
    let
        aa0 =
            case m.s.groupSortBy of
                SortName -> List.sortBy .name aa
                _ -> aa
    in
        if m.s.groupSortOrder then aa0 else List.reverse aa0


makeGroup m a =
    div []
        [ Card.card Card.config
             { blocks =
                   ( Card.block <|
                         div View.Style.cardInnerHeader
                         [ text a.name ]
                   , [ Card.block <|
                           div View.Style.cardInnerContent
                           [ cardContent m a |> text
                           ]
                     ]
                   )
             , actions = groupCardActions m a
            }
        ]

cardContent m u =
    let
        options = List.map (\(k, v) -> k ++ "=" ++ v) (Dict.toList u.options)
    in
        View.Shared.maybeItems 12 u.permissions "Permissions" 60
        ++ View.Shared.maybeItems 12 options "Options" 60

groupCardActions m a =
    Just <|
        Card.actions
            { buttons =
                  [ Card.button (Button.config
                                |> Button.setOnClick (DeleteGroup a.name)
                                |> Button.setAttributes [ style "color" "red" ]
                                ) "Delete"
                  , Card.button (Button.config
                                |> Button.setOnClick (ShowEditGroupDialog a)
                                ) "Edit"
                  , Card.button (Button.config
                                |> Button.setOnClick (ShowEditPermissionsDialog a.name)
                                ) "Permissions"
                  ]
            , icons = []
            }


maybeShowCreateGroupFab m =
    if m.s.createGroupDialogShown then
        []
    else
        [ Fab.fab
              (Fab.config
              |> Fab.setOnClick ShowCreateGroupDialog
              |> Fab.setAttributes View.Style.createFab
              )
              (Fab.icon "add")
        ]
