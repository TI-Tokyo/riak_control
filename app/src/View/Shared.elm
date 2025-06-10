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
    , userStatsDetail
    , maybeItems
    , checkboxStateFromBool
    )

import Msg exposing (..)
import Model exposing (Model)
import Util

import Html exposing (Html, text, div)
import Html.Attributes exposing (style)
import Material.Dialog as Dialog
import Material.Button as Button
import Material.Checkbox as Checkbox
import Material.List as List
import Material.List.Item as ListItem
import Filesize


userStatsDetail {total_files, total_dirs, total_size} =
    let
        maybeS = \n -> case n of
                           1 -> ""
                           _ -> "s"
    in
    (Filesize.format total_size) ++ " (" ++ String.fromInt total_size ++ " bytes) in "
        ++ String.fromInt total_files ++ " file" ++ (maybeS total_files) ++ " in "
        ++ String.fromInt total_dirs ++ " dir" ++ (maybeS total_dirs)


groupsAsList m allGids selected msg =
    let
        selectArg =
            \p ->
                if List.member p selected then
                    Just ListItem.selected
                else
                    Nothing
        element =
            case allGids of
                [] ->
                    text "(no groups)"
                p0 :: pn ->
                    List.list List.config
                        (ListItem.listItem
                             (ListItem.config
                             |> ListItem.setSelected (selectArg p0)
                             |> ListItem.setOnClick (msg p0))
                             [ text <| .name <| Model.groupBy m .id p0 ])
                        (List.map (\p ->
                                       (ListItem.listItem
                                            (ListItem.config
                                            |> ListItem.setSelected (selectArg p)
                                            |> ListItem.setOnClick (msg p))
                                            [ text <| .name <| Model.groupBy m .id p ]))
                             pn)
    in
        div [] [element]



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
