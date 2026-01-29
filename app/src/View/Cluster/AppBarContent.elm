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

module View.Cluster.AppBarContent exposing
    ( makeFilterControls
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import View.Common exposing (SortByField(..))
import View.Shared
import View.Style

import Html exposing (Html, text, div, img)
import Html.Attributes exposing (attribute, style, src)
import Material.Button as Button
import Material.TextField as TextField
import Material.Typography as Typography
import Material.Select as Select
import Material.Select.Item as SelectItem



makeFilterControls m =
    let n = View.Common.selectSortByString SortName in
    [ Select.outlined
          (Select.config
          |> Select.setLabel (Just "Sort by")
          |> Select.setSelected (Just (View.Common.selectSortByString m.s.clusterMemberSortBy))
          |> Select.setOnChange ClusterMemberSortByFieldChanged
          )
          (SelectItem.selectItem (SelectItem.config { value = n }) n)
          (List.map
               (\i -> let j = View.Common.selectSortByString i in
                      SelectItem.selectItem (SelectItem.config {value = j}) j)
               [ SortUptime
               , SortMemTotal
               , SortMemErlang
               , SortMemUsed
               ])
    , Button.text (Button.config |> Button.setOnClick ClusterMemberSortOrderChanged)
            (View.Common.sortOrderText m.s.clusterMemberSortOrder)
    ]
