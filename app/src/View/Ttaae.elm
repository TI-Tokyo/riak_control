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

module View.Ttaae exposing
    ( makeContent
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.Ttaae
import View.Common exposing (SortByField(..))
import View.Shared
import View.Style
import Util

import Html exposing (Html, text, div, img, pre)
import Html.Attributes exposing (attribute, style, src)
import Material.List as List
import Material.List.Item as ListItem
import Material.DataTable as DataTable
import Material.Typography as Typography
import Dict


makeContent m =
    if m.s.ttaaeReport == Dict.empty then
        div [ style "align-content" "center" ] [text "nothing to show" ]
    else
        makeProperContent m

makeProperContent m =
    let
        cell = (\a -> DataTable.cell [] [ text a ])
        row = (\{partition, status, lastRebuild, nextRebuild, totalDirtySegments, controllerPid} ->
                   DataTable.row []
                          [ cell partition
                          , cell (Data.Ttaae.ttaeTreeStatusToStr status)
                          , cell lastRebuild
                          , cell nextRebuild
                          , cell (String.fromInt totalDirtySegments)
                          , cell controllerPid
                          ])
        report = Dict.get m.s.ttaaeReportShownForNode m.s.ttaaeReport
               |> Maybe.withDefault [] |> sort m
    in
        div View.Style.topContent
            [ DataTable.dataTable DataTable.config
                  { thead =
                        [ DataTable.row []
                              [ cell "Partition"
                              , cell "Status"
                              , cell "Last rebuild"
                              , cell "Next rebuild"
                              , cell "Dirty segments"
                              , cell "Controller PID"
                              ]
                        ]
                  , tbody = List.map row report
              }
        ]

sort m aa =
    let
        aa0 =
            case m.s.ttaaeTreeSortBy of
                SortTtaaeTreeStatus -> List.sortWith (Data.Ttaae.compareByTreeStatus .status) aa
                SortTtaaeTreeLastRebuild -> List.sortBy .lastRebuild aa
                SortTtaaeTreeNextRebuild -> List.sortBy .nextRebuild aa
                SortTtaaeTreeTotalDirtySegments -> List.sortBy .totalDirtySegments aa
                _ -> aa
    in
        if m.s.ttaaeTreeSortOrder then aa0 else List.reverse aa0

