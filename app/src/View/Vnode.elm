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
import Numeral


makeContent m =
    if m.s.vnodeStatus == Dict.empty then
        div [ style "align-content" "center" ] [ text "nothing to show" ]
    else
        makeProperContent m

makeProperContent m =
    let
        row = \{idx, vnodeId, backendStatus, counter, counterLease, counterLeaseSize, counterLeasing} ->
                  DataTable.row []
                      (if m.s.vnodeStatusExtended then
                           [ cell idx
                           , cell (humanReadable backendStatus.mod)
                           ] ++ (backendStatusToCells m.s.vnodeStatusExtended backendStatus.status) ++
                           [ cellr (String.fromInt counter)
                           , cellr (String.fromInt counterLease)
                           , cellr (String.fromInt counterLeaseSize)
                           , cell (boolToStr counterLeasing)
                           , cell vnodeId
                           ]
                       else
                           [ cell idx
                           ] ++ (backendStatusToCells m.s.vnodeStatusExtended backendStatus.status) ++
                           [ cellr (String.fromInt counter)
                           ])
        report = Dict.get m.s.vnodeStatusShownForNode m.s.vnodeStatus
               |> Maybe.withDefault [] |> sort m
    in
        div View.Style.topContent
            [ DataTable.dataTable DataTable.config
                  { thead =
                        [ DataTable.row []
                              (if m.s.vnodeStatusExtended then
                                   [ cell "Partition"
                                   , cell "Backend"
                                   ] ++ (backendStatusToColName m.s.vnodeStatusExtended "riak_kv_leveled_backend") ++
                                   [ cell "Counter"
                                   , cell "Counter Lease"
                                   , cell "Counter Lease Size"
                                   , cell "Counter Leasing"
                                   , cell "Vnode ID"
                                   ]
                               else
                                   [ cell "Partition"
                                   ] ++ (backendStatusToColName m.s.vnodeStatusExtended "riak_kv_leveled_backend") ++
                                   [ cell "Counter"
                                   ])
                        ]
                  , tbody = List.map row report
              }
        ]

backendStatusToCells extended s =
    case s of
        Vnode.Leveled a ->
            if extended then
                [ cellr (itoa a.ledgerCacheSize)
                , cellr (itoa a.nActiveJournalFiles)
                , cellr (ftoa a.avgCompactionScore)
                , cell (countByLevelToStr a.levelFilesCount)
                , cellr (itoa a.pencillerInmemCacheSize)
                , cell (pencillerWorkBacklogStatusToStr a.pencillerWorkBacklogStatus)
                , cell (Maybe.withDefault "n/a" a.pencillerLastMergeTime)
                , cell (Maybe.withDefault "n/a" a.journalLastCompactionTime)
                , cell (journalLastCompactionResultToStr a.journalLastCompactionResult)
                , cell (String.join "/" (List.filterMap itoa2 [a.getSampleCount, a.headSampleCount, a.putSampleCount]))
                , cellr (fetchCountByLevelToStr a.fetchCountByLevel)
                ]
            else
                [ cellr (itoa a.ledgerCacheSize)
                , cellr (itoa a.nActiveJournalFiles)
                , cell (countByLevelToStr a.levelFilesCount)
                , cell (Maybe.withDefault "n/a" a.pencillerLastMergeTime)
                , cell (journalLastCompactionResultToStr a.journalLastCompactionResult)
                , cell (String.join "/" (List.filterMap itoa2 [a.getSampleCount, a.headSampleCount, a.putSampleCount]))
                ]
        Vnode.Leveldb _ ->
            [ cell "(not supported)" ]
itoa a =
    case a of
        Just x -> String.fromInt x
        Nothing -> "n/a"
itoa2 a =
    case a of
        Just x -> Just (String.fromInt x)
        Nothing -> Nothing
ftoa a =
    case a of
        Just x -> Numeral.format "0.00" x
        Nothing -> "n/a"

ledgerCacheSizeToStr {size, memory} =
    (String.fromInt size) ++ "(" ++ (String.fromInt memory) ++ ")"

countByLevelToStr aa =
    let
        f =
            \{level, count} ->
                (String.fromInt level) ++ ":" ++ (String.fromInt count)
    in
        case aa of
            Just ll ->
                List.map f ll |> String.join " "
            Nothing -> "n/a"

journalLastCompactionResultToStr a =
    case a of
        Just {filesCompacted, score} ->
            (String.fromInt filesCompacted) ++ ":" ++ (Numeral.format "0.00" score)
        Nothing -> "n/a"

pencillerWorkBacklogStatusToStr a =
    case a of
        Just {workItems, backlog, l0Full} ->
            (String.fromInt workItems) ++ " " ++ (boolToStr backlog) ++ " " ++ (boolToStr l0Full)
        Nothing -> "n/a"


fetchCountByLevelToStr a =
    case a of
        Just {notFound, mem, zero, one, two, three, lower} ->
            "notf: "++(String.fromInt notFound.count)++", "++(String.fromInt notFound.time)++" | "++
            "mem: "++(String.fromInt mem.count)++", "++(String.fromInt mem.time)++" | "++
            "L0: "++(String.fromInt zero.count)++", "++(String.fromInt zero.time)++" | "++
            "L1: "++(String.fromInt one.count)++", "++(String.fromInt one.time)++" | "++
            "L2: "++(String.fromInt two.count)++", "++(String.fromInt two.time)++" | "++
            "L3: "++(String.fromInt three.count)++", "++(String.fromInt three.time)++" | "++
            "L4+: "++(String.fromInt lower.count)++", "++(String.fromInt lower.time)
        Nothing ->
            "n/a"

backendStatusToColName extended s =
    case s of
        "riak_kv_leveled_backend" ->
            if extended then
                [ cell "Ledger Cache"
                , cell "# Active Journal Files"
                , cell "Avg Compaction Score"
                , cell "Level Files Count"
                , cell "Penciller Inmem Cache"
                , cell "Penciller Work Backlog Status"
                , cell "Penciller Last Merge Time"
                , cell "Journal Last Compaction Time"
                , cell "Journal Last Compaction Result"
                , cell "GET/HEAD/PUT Count"
                , cell "Recent Fetch Count by Level"
                ]
            else
                [ cell "Ledger Cache"
                , cell "# Active Journal Files"
                , cell "Level Files Count"
                , cell "Penciller Last Merge Time"
                , cell "Journal Last Compaction Result"
                , cell "GET/HEAD/PUT Count"
                ]
        _ ->
            []

sort m aa =
    let
        sCmp f =
            \a b ->
                case (a.backendStatus.status, b.backendStatus.status) of
                    (Vnode.Leveled s1, Vnode.Leveled s2) ->
                        case (f s1, f s2) of
                            (Just s1f, Just s2f) ->
                                if s1f > s2f then
                                    GT
                                else if s1f < s2f then
                                         LT
                                     else
                                         EQ
                            (Just _, Nothing) ->
                                GT
                            (Nothing, Just _) ->
                                LT
                            _ -> EQ
                    _ ->
                        EQ
        lfcCmp =
            let
                lfc =
                    \d ->
                        case d of
                            Just dd -> List.foldl (\{count} q -> count + q) 0 dd
                            Nothing -> 0
            in
                \a b ->
                    case (a.backendStatus.status, b.backendStatus.status) of
                        (Vnode.Leveled s1, Vnode.Leveled s2) ->
                            let (k1, k2) = (lfc s1.levelFilesCount, lfc s2.levelFilesCount) in
                            if k1 > k2 then
                                GT
                            else if k1 < k2 then
                                     LT
                                 else
                                     EQ
                        _ ->
                            EQ
        aa0 =
            case m.s.vnodeStatusSortBy of
                SortVnodeBEStatusLedgerCacheSize -> List.sortWith (sCmp .ledgerCacheSize) aa
                SortVnodeBEStatusNActiveJournalFiles -> List.sortWith (sCmp .nActiveJournalFiles) aa
                SortVnodeBEStatusPencillerLastMergeTime -> List.sortWith (sCmp .pencillerLastMergeTime) aa
                SortVnodeBEStatusJournalLastCompactionTime -> List.sortWith (sCmp .journalLastCompactionTime) aa
                SortVnodeBEStatusLevelFilesCountTotal -> List.sortWith lfcCmp aa
                SortVnodeBEStatusGetCount -> List.sortWith (sCmp .getSampleCount) aa
                SortVnodeBEStatusHeadCount -> List.sortWith (sCmp .headSampleCount) aa
                SortVnodeBEStatusPutCount -> List.sortWith (sCmp .putSampleCount) aa
                SortVnodeStatusCounter -> List.sortBy .counter aa
                SortVnodeStatusCounterLease -> List.sortBy .counterLease aa
                _ -> aa
    in
        if m.s.vnodeStatusSortOrder then aa0 else List.reverse aa0

cell a = DataTable.cell ([ style "text-align" "left" ] ++ (maybeGrey a)) [ text a ]
cellr a = DataTable.cell ([ style "text-align" "right" ] ++ (maybeGrey a)) [ text a ]

maybeGrey a =
    if a == "n/a" then [ style "color" "#cbcbcb" ] else []

boolToStr a =
    case a of
        True -> "yes"
        False -> "no"

humanReadable a =
    case a of
        "riak_kv_leveled_backend" -> "leveled"
        "riak_kv_leveldb_backend" -> "leveldb"
        "riak_kv_bitcask_backend" -> "bitcask"
        _ -> a
