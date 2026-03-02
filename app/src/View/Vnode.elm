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

module View.Vnode exposing
    ( makeContent
    , backendString
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
import Numeral
import Dict as Dict
import Time
import Iso8601

backendString m =
    case m.s.vnodeStatus of
        (first :: _) -> vnodeBackendString first.backendStatus
        _ -> "??"

vnodeBackendString x =
    case x of
        Vnode.Leveled _ -> "leveled"
        Vnode.Leveldb _ -> "leveldb"
        Vnode.Bitcask _ -> "bitcask"
        Vnode.Memory _ -> "memory"
        Vnode.Multi bb -> "multi(" ++ (Dict.keys bb.backendStatus |> String.join ", ") ++ ")"
        Vnode.PrefixMulti bb -> "prefix_multi" ++ (String.join ", " (Dict.keys bb.backendStatus)) ++ ")"


makeContent m =
    if m.s.vnodeStatus == [] then
        div [ style "align-content" "center" ] [ text "nothing to show" ]
    else
        makeProperContent m

makeProperContent m =
    let
        row = \{idx, vnodeId, backendStatus, counter, counterLease, counterLeaseSize, counterLeasing} ->
                  DataTable.row []
                      (if m.s.vnodeStatusExtended then
                           [ cellr idx
                           ] ++ (backendStatusToCells m.s.vnodeStatusExtended backendStatus) ++
                           [ cellr (String.fromInt counter)
                           , cellr (String.fromInt counterLease)
                           , cellr (String.fromInt counterLeaseSize)
                           , cell (boolToStr counterLeasing)
                           , cell vnodeId
                           ]
                       else
                           [ cellr (ellipsize idx)
                           ] ++ (backendStatusToCells m.s.vnodeStatusExtended backendStatus) ++
                           [ cellr (String.fromInt counter)
                           ])
        report = m.s.vnodeStatus |> sort m
        backendName = backendString m
    in
        div View.Style.topContent
            [ text ("Backend: " ++ backendName)
            , DataTable.dataTable DataTable.config
                  { thead =
                        [ DataTable.row []
                              (if m.s.vnodeStatusExtended then
                                   [ cell "Partition"
                                   ] ++ (backendStatusToColName m.s.vnodeStatusExtended backendName) ++
                                   [ cell "Counter"
                                   , cell "Counter Lease"
                                   , cell "Counter Lease Size"
                                   , cell "Counter Leasing"
                                   , cell "Vnode ID"
                                   ]
                               else
                                   [ cell "Partition"
                                   ] ++ (backendStatusToColName m.s.vnodeStatusExtended backendName) ++
                                   [ cell "Counter"
                                   ])
                        ]
                  , tbody = List.map row report
              }
        ]

sort m aa =
    let
        sCmpBitcask f =
            \a b ->
                case (a.backendStatus, b.backendStatus) of
                    (Vnode.Bitcask s1, Vnode.Bitcask s2) ->
                        Util.cmp (f s1) (f s2)
                    _ ->
                        EQ
        sCmpLeveled f =
            \a b ->
                case (a.backendStatus, b.backendStatus) of
                    (Vnode.Leveled s1, Vnode.Leveled s2) ->
                        Util.cmp (f s1) (f s2)
                    _ ->
                        EQ
        sCmpLeveldb f =
            \a b ->
                case (a.backendStatus, b.backendStatus) of
                    (Vnode.Leveldb s1, Vnode.Leveldb s2) ->
                        Util.cmp (f s1) (f s2)
                    _ ->
                        EQ
        sCmpMemory f =
            \a b ->
                case (a.backendStatus, b.backendStatus) of
                    (Vnode.Memory s1, Vnode.Memory s2) ->
                        Util.cmp (f s1) (f s2)
                    _ ->
                        EQ
        sCmpMaybe f =
            \a b ->
                case (a.backendStatus, b.backendStatus) of
                    (Vnode.Leveled s1, Vnode.Leveled s2) ->
                        case (f s1, f s2) of
                            (Just s1f, Just s2f) ->
                                Util.cmp s1f s2f
                            (Just _, Nothing) ->
                                GT
                            (Nothing, Just _) ->
                                LT
                            _ -> EQ
                    _ ->
                        EQ
        leveledLfcCmp =
            let lfc = \dd -> List.foldl (\{count} q -> count + q) 0 dd in
            \a b ->
                case (a.backendStatus, b.backendStatus) of
                    (Vnode.Leveled s1, Vnode.Leveled s2) ->
                        Util.cmp (lfc s1.levelFilesCount) (lfc s2.levelFilesCount)
                    _ ->
                        EQ
        bitcaskBytesCmp f =
            let lfc = \dd -> List.foldl (\o q -> f o + q) 0 dd in
            \a b ->
                case (a.backendStatus, b.backendStatus) of
                    (Vnode.Bitcask s1, Vnode.Bitcask s2) ->
                        Util.cmp (lfc s1.status) (lfc s2.status)
                    _ ->
                        EQ
        aa0 =
            case m.s.vnodeStatusSortBy of
                SortUnsorted -> List.sortBy (.idx >> String.toInt >> Maybe.withDefault 0) aa |> List.reverse
                SortVnodeLeveledLedgerCacheSize -> List.sortWith (sCmpMaybe .ledgerCacheSize) aa
                SortVnodeLeveledNActiveJournalFiles -> List.sortWith (sCmpLeveled .nActiveJournalFiles) aa
                SortVnodeLeveledPencillerLastMergeTime -> List.sortWith (sCmpMaybe .pencillerLastMergeTime) aa
                SortVnodeLeveledJournalLastCompactionTime -> List.sortWith (sCmpMaybe .journalLastCompactionTime) aa
                SortVnodeLeveledLevelFilesCountTotal -> List.sortWith leveledLfcCmp aa
                SortVnodeLeveledGetCount -> List.sortWith (sCmpLeveled .getSampleCount) aa
                SortVnodeLeveledHeadCount -> List.sortWith (sCmpLeveled .headSampleCount) aa
                SortVnodeLeveledPutCount -> List.sortWith (sCmpLeveled .putSampleCount) aa
                SortVnodeLeveldbFilesize -> List.sortWith (sCmpLeveldb (.filesSizeMb >> Maybe.withDefault 0)) aa
                SortVnodeLeveldbCompactions -> List.sortWith (sCmpLeveldb (.compactions >> Maybe.withDefault 0)) aa
                SortVnodeLeveldbReadMb -> List.sortWith (sCmpLeveldb (.readMb >> Maybe.withDefault 0)) aa
                SortVnodeLeveldbWriteMb -> List.sortWith (sCmpLeveldb (.writeMb >> Maybe.withDefault 0)) aa
                SortVnodeBitcaskKeycount -> List.sortWith (sCmpBitcask .keyCount) aa
                SortVnodeBitcaskDeadbytes -> List.sortWith (bitcaskBytesCmp .deadBytes) aa
                SortVnodeBitcaskTotalbytes -> List.sortWith (bitcaskBytesCmp .totalBytes) aa
                SortVnodeMemoryUsedMemory -> List.sortWith (sCmpMemory .usedMemory) aa
                SortVnodeMemoryPutObjSize -> List.sortWith (sCmpMemory .putObjSize) aa
                SortVnodeMemoryDataMemory -> List.sortWith (sCmpMemory (.dataTableStatus >> .memory)) aa
                SortVnodeMemoryIndexMemory -> List.sortWith (sCmpMemory (.indexTableStatus >> .memory)) aa
                SortVnodeStatusCounter -> List.sortBy .counter aa
                SortVnodeStatusCounterLease -> List.sortBy .counterLease aa
                _ -> aa
    in
        if m.s.vnodeStatusSortOrder then aa0 else List.reverse aa0


backendStatusToCells ext s =
    case s of
        Vnode.Bitcask a ->
            bitcaskBackendStatusToCells ext a
        Vnode.Memory a ->
            memoryBackendStatusToCells ext a
        Vnode.Leveldb a ->
            leveldbBackendStatusToCells ext a
        Vnode.Leveled a ->
            leveledBackendStatusToCells ext a
        Vnode.Multi a ->
            multiBackendStatusToCells ext a
        Vnode.PrefixMulti a ->
            multiBackendStatusToCells ext a


bitcaskBackendStatusToCells _ a =
    [ cellr (dtoa a.keyCount)
    , cell (filestatustoa a.status)
    ]
filestatustoa a =
    let fragfmtoa = \f -> if f then "#" else " " in
    List.map (\{filename, fragmented, deadBytes, totalBytes} ->
                  filename ++ (fragfmtoa fragmented) ++
                  (String.fromInt deadBytes) ++ ":" ++
                  (String.fromInt totalBytes)) a |> String.join " "


memoryBackendStatusToCells ext a =
    if ext then
        [ cellr (dtoa a.usedMemory)
        , cellr (dtoa a.putObjSize)
        , cellr (dtoa a.dataTableStatus.memory)
        , cellr (dtoa a.dataTableStatus.size)
        , cell a.dataTableStatus.owner
        , cellr (boolToStr a.dataTableStatus.readConcurrency)
        , cellr (boolToStr a.dataTableStatus.writeConcurrency)
        , cellr (boolToStr a.dataTableStatus.compressed)
        , cellr (dtoa a.indexTableStatus.memory)
        , cellr (dtoa a.indexTableStatus.size)
        , cell a.indexTableStatus.owner
        , cellr (boolToStr a.indexTableStatus.readConcurrency)
        , cellr (boolToStr a.indexTableStatus.writeConcurrency)
        , cellr (boolToStr a.indexTableStatus.compressed)
        ]
    else
        [ cellr (dtoa a.usedMemory)
        , cellr (dtoa a.putObjSize)
        , cellr (dtoa a.dataTableStatus.memory)
        , cellr (dtoa a.dataTableStatus.size)
        , cellr (dtoa a.indexTableStatus.memory)
        , cellr (dtoa a.indexTableStatus.size)
        ]


leveldbBackendStatusToCells _ a =
    [ cellr (itoa a.compactions)
    , cellr (itoa a.filesSizeMb)
    , cell (boolToStr a.fixedIndexes)
    , cellr (itoa a.level)
    , cellr a.readBlockError
    , cellr (itoa a.readMb)
    , cellr (itoa a.time)
    , cellr (itoa a.writeMb)
    ]


leveledBackendStatusToCells extended a =
    let
        fetchCountByLevelToStr =
            \x ->
                case x of
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
        ledgerCacheSizeToStr =
            \{size, memory} ->
                (String.fromInt size) ++ "(" ++ (String.fromInt memory) ++ ")"

        countByLevelToStr =
            \x ->
                List.map (\{level, count} ->
                              (String.fromInt level) ++ ":" ++ (String.fromInt count)) x
                    |> String.join " "

        journalLastCompactionResultToStr =
            \x ->
                case x of
                    Just {filesCompacted, score} ->
                        (String.fromInt filesCompacted) ++ ":" ++ (Numeral.format "0.00" score)
                    Nothing -> "n/a"

        pencillerWorkBacklogStatusToStr =
            \x ->
                case x of
                    Just {workItems, backlog, l0Full} ->
                        (String.fromInt workItems) ++ " " ++ (boolToStr backlog) ++ " " ++ (boolToStr l0Full)
                    Nothing -> "n/a"
    in
        if extended then
            [ cellr (itoa a.ledgerCacheSize)
            , cell (countByLevelToStr a.levelFilesCount)

            , cellr (itoa a.pencillerInmemCacheSize)
            , cell (pencillerWorkBacklogStatusToStr a.pencillerWorkBacklogStatus)
            , cell (Maybe.withDefault "n/a" a.pencillerLastMergeTime)

            , cellr (dtoa a.nActiveJournalFiles)
            , cellr (Maybe.withDefault "n/a" a.journalLastCompactionTime)
            , cellr (itoa a.journalLastCompactionDuration)
            , cellr (ftoa a.journalLastCompactionScore)
            , cellr (ftoa a.journalLastCompactionMean)
            , cellr (ftoa a.journalLastCompactionMax)
            , cellr (itoa a.journalLastCompactionRunlength)

            , cellr (fetchCountByLevelToStr a.fetchCountByLevel)
            , cell (String.join "/" (List.map dtoa [a.getSampleCount, a.headSampleCount, a.putSampleCount]))
            ]
        else
            [ cellr (itoa a.ledgerCacheSize)
            , cell (countByLevelToStr a.levelFilesCount)

            , cellr (itoa a.pencillerInmemCacheSize)
            , cell (Maybe.withDefault "n/a" a.pencillerLastMergeTime)

            , cellr (dtoa a.nActiveJournalFiles)
            , cellr (Maybe.withDefault "n/a" a.journalLastCompactionTime)
            , cellr (ftoa a.journalLastCompactionScore)
            , cellr (ftoa a.journalLastCompactionMean)

            , cell (String.join "/" (List.map dtoa [a.getSampleCount, a.headSampleCount, a.putSampleCount]))
            ]


multiBackendStatusToCells _ a =
    [ cell "tbd" ]


backendStatusToColName extended s =
    case s of
        "bitcask" ->
            [ cell "Key count"
            , cell "Status"
            ]
        "memory" ->
            if extended then
                [ cell "Used memory"
                , cell "Put obj size"
                , cell "Data Memory"
                , cell "Data Size"
                , cell "Data Owner"
                , cell "Data Read concurrency"
                , cell "Data Write concurrency"
                , cell "Data Compressed"
                , cell "Index Memory"
                , cell "Index Size"
                , cell "Index Owner"
                , cell "Index Read concurrency"
                , cell "Index Write concurrency"
                , cell "Index Compressed"
                ]
            else
                [ cell "Used memory"
                , cell "Put obj size"
                , cell "Data Memory"
                , cell "Data Size"
                , cell "Index Memory"
                , cell "Index Size"
                ]
        "leveldb" ->
            [ cell "Compactions"
            , cell "Files size (MB)"
            , cell "Fixed indexes"
            , cell "Level"
            , cell "Read block error"
            , cell "Read (MB)"
            , cell "Time"
            , cell "Write (MB)"
            ]
        "leveled" ->
            if extended then
                [ cell "Ledger Cache"
                , cell "Level Files"

                , cell "Pcl Cache"
                , cell "Pcl Backlog"
                , cell "Pcl Last Merge"

                , cell "# Jnl Files"
                , cell "Jnl Last Cmp Time"
                , cell "Jnl Last Cmp Dur"
                , cell "Jnl Last Cmp Score"
                , cell "Jnl Last Cmp Max"
                , cell "Jnl Last Cmp Avg"
                , cell "Jnl Last Cmp Runlen"

                , cell "Fetch Counts"
                , cell "GET/HEAD/PUT Count"
                ]
            else
                [ cell "Ledger Cache"
                , cell "Level Files"
                , cell "Pcl Cache"
                , cell "Pcl Last Merge"
                , cell "# Jnl Files"
                , cell "Jnl Last Cmp Time"
                , cell "Jnl Last Cmp Score"
                , cell "Jnl Last Cmp Avg"
                , cell "GET/HEAD/PUT Count"
                ]
        _ ->
            []

cell a = DataTable.cell ([ style "text-align" "left" ] ++ (maybeGrey a)) [ text a ]
cellr a = DataTable.cell ([ style "text-align" "right" ] ++ (maybeGrey a)) [ text a ]

maybeGrey a =
    if a == "n/a" then [ style "color" "#cbcbcb" ] else []

boolToStr a =
    case a of
        True -> "yes"
        False -> "no"


ellipsize a =
    if a == "0" then a else
        let
            l = String.left 4 a
            r = String.right 4 a
        in
            l ++ ".." ++ r
itoa a =
    case a of
        Just x -> String.fromInt x
        Nothing -> "n/a"

dtoa a =
    String.fromInt a

itoa2 a =
    case a of
        Just x -> Just (String.fromInt x)
        Nothing -> Nothing

ftoa a =
    case a of
        Just x -> Numeral.format "0.00" x
        Nothing -> "n/a"
