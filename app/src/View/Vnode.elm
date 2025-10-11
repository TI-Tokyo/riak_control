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

module View.Vnode exposing
    ( makeContent
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.Vnode as Vnode
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
    if m.s.vnodeStatus == Dict.empty then
        div [ style "align-content" "center" ] [text "nothing to show" ]
    else
        makeProperContent m

makeProperContent m =
    let
        row = \{idx, vnodeId, backendStatus, counter, counterLease, counterLeaseSize, counterLeasing} ->
                  DataTable.row []
                      ([ cell idx
                      , cell vnodeId
                      , cell (humanReadable backendStatus.mod)
                      ] ++ (backendStatusToCells backendStatus.status) ++
                      [ cellr (String.fromInt counter)
                      , cellr (String.fromInt counterLease)
                      , cellr (String.fromInt counterLeaseSize)
                      , cell (boolToStr counterLeasing)
                      ])
        report = Dict.get m.s.vnodeStatusShownForNode m.s.vnodeStatus
               |> Maybe.withDefault [] |> sort m
    in
        div View.Style.topContent
            [ DataTable.dataTable DataTable.config
                  { thead =
                        [ DataTable.row []
                              ([ cell "Partition"
                               , cell "Vnode ID"
                               , cell "Backend"
                               ] ++ (backendStatusToColName "riak_kv_leveled_backend") ++
                               [ cell "Counter"
                               , cell "Counter Lease"
                               , cell "Counter Lease Size"
                               , cell "Counter Leasing"
                               ])
                        ]
                  , tbody = List.map row report
              }
        ]

backendStatusToCells s =
    case s of
        Vnode.Leveled a ->
            [ cell (ledgerCacheSizeToStr a.ledgerCacheSize)
            , cellr (String.fromInt a.nActiveJournalFiles)
            , cellr (String.fromFloat a.avgCompactionScore)
            , cell (countByLevelToStr a.levelFilesCount)
            , cellr (String.fromInt a.pencillerInmemCacheSize)
            , cell (a.pencillerWorkBacklogStatus)
            , cell (a.pencillerLastMergeTime)
            , cell (a.journalLastCompactionTime)
            , cell (journalLastCompactionResultToStr a.journalLastCompactionResult)
            , cellr (String.fromFloat a.metadataObjsizeRatio)
            , cell (String.join "/" (List.map String.fromInt a.recentPutgetheadCounts))
            , cellr (String.fromInt a.recentFetchMeanLevel)
            ]

ledgerCacheSizeToStr {size, memory} =
    (String.fromInt size) ++ "(" ++ (String.fromInt memory) ++ ")"

countByLevelToStr ll =
    let f = \{level, count} -> (String.fromInt level) ++ ":" ++ (String.fromInt count)
    in List.map f ll |> String.join " "

journalLastCompactionResultToStr {filesCompacted, score} =
    (String.fromInt filesCompacted) ++ ":" ++ (String.fromFloat score)

backendStatusToColName s =
    case s of
        "riak_kv_leveled_backend" ->
            [ cell "Ledger Cache"
            , cell "# Active Journal Files"
            , cell "Avg Compaction Score"
            , cell "Level Files Count"
            , cell "Penciller Inmem Cache"
            , cell "Penciller Work Backlog Status"
            , cell "Penciller Last Merge Time"
            , cell "Journal Last Compaction Time"
            , cell "Journal Last Compaction Result"
            , cell "Metadata to Objsize Ratio"
            , cell "Recent PUT/GET/HEAD Counts"
            , cell "Recent Fetch Mean Level"
            ]
        _ ->
            []

sort m aa =
    let
        aa0 =
            case m.s.vnodeStatusSortBy of
                _ -> aa
    in
        if m.s.vnodeStatusSortOrder then aa0 else List.reverse aa0

cell a = DataTable.cell [ style "text-align" "left" ] [ text a ]
cellr a = DataTable.cell [ style "text-align" "right" ] [ text a ]

boolToStr a =
    case a of
        True -> "yes"
        False -> "no"

humanReadable a =
    case a of
        "riak_kv_leveled_backend" -> "leveled"
        "riak_kv_leveldb_backend" -> "leveldb"
        "riak_kv_bitcask_backend" -> "bitcask"
        _ -> ""
