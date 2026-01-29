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

module View.Vnode.AppBarContent exposing
    ( makeFilterControls
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import View.Common exposing (SortByField(..))
import View.Shared
import View.Style
import Util

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (attribute, style, src)
import Material.Button as Button
import Material.TextField as TextField
import Material.Select as Select
import Material.Select.Item as SelectItem
import Material.Checkbox as Checkbox
import Material.FormField as FormField
import Material.Typography as Typography



makeFilterControls m =
    let
        n = View.Common.selectSortByString SortUnsorted
        (k0, kx) =
            Util.headAndTail (List.map .name m.s.cluster.current) "??"
    in
        [ Select.outlined
              (Select.config
              |> Select.setLabel (Just "Node")
              |> Select.setSelected (Just m.s.vnodeStatusShownForNode)
              |> Select.setOnChange VnodeStatusShowForNodeChanged
              )
              (SelectItem.selectItem
                   (SelectItem.config { value = k0 })
                   k0
              )
              (List.map (\k -> SelectItem.selectItem
                             (SelectItem.config { value = k })
                             k) kx)
        , Select.outlined
              (Select.config
              |> Select.setLabel (Just "Sort by")
              |> Select.setSelected (Just (View.Common.selectSortByString m.s.vnodeStatusSortBy))
              |> Select.setOnChange VnodeStatusSortByFieldChanged
              )
              (SelectItem.selectItem (SelectItem.config { value = n }) n)
              (List.map
                   (\i -> let j = View.Common.selectSortByString i in
                          SelectItem.selectItem (SelectItem.config {value = j}) j)
                   [ SortUnsorted
                   , SortVnodeBEStatusLedgerCacheSize
                   , SortVnodeBEStatusNActiveJournalFiles
                   , SortVnodeBEStatusPencillerLastMergeTime
                   , SortVnodeBEStatusJournalLastCompactionTime
                   , SortVnodeBEStatusLevelFilesCountTotal
                   , SortVnodeBEStatusGetCount
                   , SortVnodeBEStatusHeadCount
                   , SortVnodeBEStatusPutCount
                   , SortVnodeStatusCounter
                   , SortVnodeStatusCounterLease
                   ])
        , Button.text (Button.config |> Button.setOnClick VnodeStatusSortOrderChanged)
            (View.Common.sortOrderText m.s.vnodeStatusSortOrder)
        , FormField.formField
              (FormField.config
              |> FormField.setLabel (Just "Extended")
              )
              [ Checkbox.checkbox
                    (Checkbox.config
                    |> Checkbox.setState
                         (View.Shared.checkboxStateFromBool
                              m.s.vnodeStatusExtended)
                    |> Checkbox.setOnChange VnodeStatusExtendedToggle
                    )
              ]
        ]
