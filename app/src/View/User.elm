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

module View.User exposing
    ( makeContent
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import View.User.Dialog
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
import Material.Chip.Filter as FilterChip
import Material.ChipSet.Filter as FilterChipSet
import Iso8601
import Dict


makeContent m =
    div View.Style.topContent
        [ div View.Style.card (makeUsers m)
        , div [] (View.User.Dialog.makeCreateUserDialog m)
        , div [] (View.User.Dialog.makeEditUserDialog m)
        , div [] (View.Shared.makeDeleteThingConfirmDialog
                      m .confirmDeleteUserDialogShownFor
                      (.name << (Model.userBy m .name)) "user"
                      DeleteUserConfirmed DeleteUserNotConfirmed)
        , div [] (maybeShowCreateUserFab m)
        ]


makeUsers m =
    case m.s.users |> (filter m) |> (sort m) |> List.map (makeUser m) of
        [] ->
            [ img [src "images/filter-man.jpg"] [] ]
        rr ->
            rr

filter m uu =
    case m.s.userFilterValue of
        "" -> uu
        s ->
            List.filter
                (\u ->
                     (  (List.member "Name" m.s.userFilterIn && String.contains s u.name)
                     )
                ) uu

sort m aa =
    let
        aa0 =
            case m.s.userSortBy of
                Name -> List.sortBy .name aa
                _ -> aa
    in
        if m.s.userSortOrder then aa0 else List.reverse aa0


makeUser m u =
    div []
        [ Card.card Card.config
             { blocks =
                   ( Card.block <|
                         div View.Style.cardInnerHeader
                         [ text u.name ]
                   , [ Card.block <|
                           div View.Style.cardInnerContent
                           [ cardContent m u |> text
                           ]
                     ]
                   )
             , actions = userCardActions m u
            }
        ]

cardContent m u =
    let
        options = List.map (\(k, v) -> k ++ "=" ++ v) (Dict.toList u.options)
    in
        "          Name: " ++ u.name ++ "\n" ++
        " Password hash: " ++ u.password_hash
        ++ View.Shared.maybeItems 16 u.groups "Groups" 60
        ++ View.Shared.maybeItems 16 options "Options" 60

userCardActions m u =
    Just <|
        Card.actions
            { buttons =
                  [ Card.button (Button.config
                                |> Button.setOnClick (DeleteUser u.name)
                                |> Button.setDisabled (isRoot u)
                                |> Button.setAttributes [ style "color" "red" ]
                                ) "Delete"
                  , Card.button (Button.config
                                |> Button.setOnClick (ShowEditUserDialog u)
                                |> Button.setDisabled (isRoot u)
                                ) "Edit"
                  ]
            , icons =
                maybeRootMark u
            }


isRoot {name} =
    name == "root"


maybeRootMark u =
    if u.name == "root" then
        [ Card.icon IconButton.config (IconButton.icon "#") ]
    else
        []


maybeShowCreateUserFab m =
    if m.s.createUserDialogShown then
        []
    else
        [ Fab.fab
              (Fab.config
              |> Fab.setOnClick ShowCreateUserDialog
              |> Fab.setAttributes View.Style.createFab
              )
              (Fab.icon "add")
        ]
