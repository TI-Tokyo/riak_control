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

module View.Shared exposing
    ( makeDeleteThingConfirmDialog
    , groupsAsList
    , grantsAsList
    , maybeItems
    , checkboxStateFromBool
    , makeEditGrantsDialog
    , makeAddGrantsDialog
    )

import Msg exposing (..)
import Model exposing (Model)
import Data.Security
import Request.Security
import View.Style
import Util

import Html exposing (Html, text, div)
import Html.Attributes exposing (style)
import Material.Dialog as Dialog
import Material.Button as Button
import Material.Checkbox as Checkbox
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.TextField as TextField
import Material.List as List
import Material.List.Item as ListItem
import Material.IconButton as IconButton


makeDeleteThingConfirmDialog m d g t confirmedMsg notConfirmedMsg =
    case d m.s of
        Just a ->
            [ Dialog.confirmation
                  (Dialog.config
                  |> Dialog.setOpen True
                  |> Dialog.setOnClose notConfirmedMsg
                  )
                  { title = "Confirm"
                  , content =
                        [ text ("Delete " ++ t ++ " \"" ++ g a ++ "\"?") ]
                  , actions =
                        [ Button.text
                              ( Button.config |> Button.setOnClick notConfirmedMsg
                              |> Button.setAttributes [ Dialog.defaultAction ]
                              )
                              "No"
                        , Button.text
                              ( Button.config
                              |> Button.setOnClick confirmedMsg
                              )
                              "Yes"
                        ]
                  }
            ]
        Nothing ->
            []


groupsAsList m allGroups selected msg =
    let
        selectArg =
            \p ->
                if List.member p selected then
                    Just ListItem.selected
                else
                    Nothing
        element =
            case allGroups of
                [] ->
                    text "(no groups)"
                p0 :: pn ->
                    List.list List.config
                        (ListItem.listItem
                             (ListItem.config
                             |> ListItem.setSelected (selectArg p0)
                             |> ListItem.setOnClick (msg p0))
                             [ text <| p0 ])
                        (List.map (\p ->
                                       (ListItem.listItem
                                            (ListItem.config
                                            |> ListItem.setSelected (selectArg p)
                                            |> ListItem.setOnClick (msg p))
                                            [ text <| p ]))
                             pn)
    in
        div [] [element]

grantsAsList m allGrants selected msg =
    let
        selectArg =
            \p ->
                if List.member p selected then
                    Just ListItem.selected
                else
                    Nothing
        -- allGrantsAsStr = List.map Data.Security.grantToStr allGrants
        element =
            case allGrants of
                [] ->
                    text "(no grants)"
                p0 :: pn ->
                    List.list List.config
                        (ListItem.listItem
                             (ListItem.config
                             |> ListItem.setSelected (selectArg p0)
                             |> ListItem.setOnClick (msg p0))
                             [ text <| p0 ])
                        (List.map (\p ->
                                       (ListItem.listItem
                                            (ListItem.config
                                            |> ListItem.setSelected (selectArg p)
                                            |> ListItem.setOnClick (msg p))
                                            [ text <| p ]))
                             pn)
    in
        div [] [element]


maybeItems : Int -> (List String) -> String -> Int -> String
maybeItems indent aa pfx linelength =
    if aa == [] then
        ""
    else
        let
            extra = " (" ++ (List.length aa |> String.fromInt) ++ "): "
            fullPfx = pfx ++ extra
        in
            "\n" ++
                (String.padLeft indent ' ' fullPfx) ++
                (limitedJoin linelength ", " indent aa)

limitedJoin linelength j indent aa =
    let
        lines =
            List.foldl
                (\a q -> let last = Maybe.withDefault "" <| List.head q in
                         case ( (String.length last) + (String.length j) + (String.length a) < linelength
                              , String.length last
                              ) of
                             (True, 0) -> (a :: List.drop 1 q)
                             (True, _) -> ((last ++ j ++ a) :: List.drop 1 q)
                             (False, _) -> (((String.repeat indent " ") ++ a) :: q)
                ) [] aa
    in
        List.reverse lines |> String.join ",\n"

checkboxStateFromBool a =
    if a then
        Just Checkbox.checked
    else
        Just Checkbox.unchecked



makeEditGrantsDialog m role =
    case m.s.openEditGrantsDialogFor of
        Just a ->
            makeEditGrantsDialog2 m role a
        Nothing ->
            []

makeEditGrantsDialog2 m role a =
    let
        (name, grants, pfx) =
            case role of
                Data.Security.UserRole -> let u = Model.userBy m .name a in (u.name, u.grants, "user")
                Data.Security.GroupRole -> let g = Model.groupBy m .name a in (g.name, g.grants, "group")
    in
    [ Dialog.confirmation
          (Dialog.config
          |> Dialog.setOpen True
          |> Dialog.setOnClose EditGrantsCancelled
          )
          { title = "Permissions granted to " ++ pfx ++ " " ++ name
          , content =
                [ div View.Style.dialogContentPart
                      ([ grantsAsList m
                             (List.map Data.Security.grantToStr grants)
                             m.s.selectedGrantsForDelete
                             SelectOrUnselectGrantToDelete ]
                           ++ [ div []
                                    [ IconButton.iconButton
                                         (IconButton.config
                                         |> IconButton.setOnClick (ShowAddGrantDialog a))
                                         (IconButton.icon "add")
                                    ,  IconButton.iconButton
                                          (IconButton.config
                                          |> IconButton.setOnClick (DeleteGrantBatch role)
                                          |> IconButton.setDisabled (m.s.selectedGrantsForDelete == [])
                                          |> IconButton.setAttributes [ style "color" "red" ])
                                          (IconButton.icon "delete")
                                    ]
                              ]
                      )
                ]
          , actions =
                [ Button.text
                      (Button.config |> Button.setOnClick EditGrantsCancelled)
                      "Dismiss"
                ]
          }
    ]


makeAddGrantsDialog m role =
    case m.s.openAddGrantsDialogFor of
        Just u ->
            makeAddGrantsDialog2 m role u
        Nothing ->
            []

makeAddGrantsDialog2 m role a =
    let
        (name, grants, pfx) =
            case role of
                Data.Security.UserRole -> let u = Model.userBy m .name a in (u.name, u.grants, "user")
                Data.Security.GroupRole -> let g = Model.groupBy m .name a in (g.name, g.grants, "group")
        (p0, pp) =
            case m.s.permissions of
                q0 :: qp -> (q0, qp)
                _ -> ("??", [])
        allUserGrants = List.map Data.Security.grantToStr grants
    in
        [ Dialog.confirmation
              (Dialog.config
              |> Dialog.setOpen True
              |> Dialog.setOnClose AddGrantDialogCancelled
              )
              { title = "New grant for " ++ pfx ++ " " ++ name
              , content =
                    [ Select.filled
                          (Select.config
                          |> Select.setLabel (Just "Permission")
                          |> Select.setOnChange AddingGrantPermissionChanged)
                          (SelectItem.selectItem (SelectItem.config { value = p0 }) p0)
                          (List.map (\px -> (SelectItem.selectItem (SelectItem.config { value = px }) px)) pp)
                    , TextField.filled
                          (TextField.config
                          |> TextField.setLabel (Just "Scope")
                          |> TextField.setValue (Just m.s.addingGrantScope)
                          |> TextField.setOnInput AddingGrantScopeChanged
                          )
                    ]
              , actions =
                    [ Button.text
                          (Button.config |> Button.setOnClick AddGrantDialogCancelled)
                          "Dismiss"
                    , Button.text
                          (Button.config
                          |> Button.setOnClick (AddGrant role)
                          |> Button.setDisabled (m.s.addingGrantPermission == "" || m.s.addingGrantScope == "")
                          |> Button.setAttributes [ Dialog.defaultAction ])
                          "Add"
                    ]
              }
        ]
