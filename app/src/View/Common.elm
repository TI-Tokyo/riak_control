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

module View.Common exposing (..)

type SortByField
    = SortName
    -- cluster
    | SortMemTotal
    | SortMemErlang
    | SortMemUsed
    | SortUptime
    -- ttaae
    | SortTtaaeTreeStatus
    | SortTtaaeTreeNextRebuild
    | SortTtaaeTreeLastRebuild
    | SortTtaaeTreeTotalDirtySegments
    -- vnode
    | SortVnodeStatusCounter
    | SortVnodeStatusCounterLease
    -- vnode: leveled
    | SortVnodeLeveledLedgerCacheSize
    | SortVnodeLeveledNActiveJournalFiles
    | SortVnodeLeveledPencillerLastMergeTime
    | SortVnodeLeveledJournalLastCompactionTime
    | SortVnodeLeveledLevelFilesCountTotal
    | SortVnodeLeveledGetCount
    | SortVnodeLeveledHeadCount
    | SortVnodeLeveledPutCount
    -- vnode: leveldb
    | SortVnodeLeveldbFilesize
    | SortVnodeLeveldbCompactions
    | SortVnodeLeveldbReadMb
    | SortVnodeLeveldbWriteMb
    -- vnode: bitcask
    | SortVnodeBitcaskKeycount
    | SortVnodeBitcaskDeadbytes
    | SortVnodeBitcaskTotalbytes
    -- vnode: memory
    | SortVnodeMemoryUsedMemory
    | SortVnodeMemoryPutObjSize
    | SortVnodeMemoryDataMemory
    | SortVnodeMemoryIndexMemory
    --
    | SortUnsorted

type alias SortOrder = Bool

sortOrderText =
    \o -> if o then "Asc" else "Desc"

selectSortByString a =
    case a of
        SortName -> "Name"
        SortMemTotal -> "Memory (total)"
        SortMemErlang -> "Memory (Erlang)"
        SortMemUsed -> "Memory (riak)"
        SortUptime -> "Uptime"
        SortTtaaeTreeStatus -> "Tree status"
        SortTtaaeTreeNextRebuild -> "Next rebuild"
        SortTtaaeTreeLastRebuild -> "Last rebuild"
        SortTtaaeTreeTotalDirtySegments -> "Total dirty segments"
        SortVnodeLeveledLedgerCacheSize -> "Ledger cache (# keys)"
        SortVnodeLeveledNActiveJournalFiles -> "# active journal files"
        SortVnodeLeveledPencillerLastMergeTime -> "Penciller last merge time"
        SortVnodeLeveledJournalLastCompactionTime -> "Journal last compaction time"
        SortVnodeLeveledLevelFilesCountTotal -> "Level files count (Total)"
        SortVnodeLeveledGetCount -> "GET count"
        SortVnodeLeveledHeadCount -> "HEAD count"
        SortVnodeLeveledPutCount -> "PUT count"
        SortVnodeLeveldbFilesize -> "File size"
        SortVnodeLeveldbCompactions -> "Compactions"
        SortVnodeLeveldbReadMb -> "Read MB"
        SortVnodeLeveldbWriteMb -> "Write MB"
        SortVnodeBitcaskKeycount -> "Key count"
        SortVnodeBitcaskDeadbytes -> "Dead bytes"
        SortVnodeBitcaskTotalbytes -> "Total bytes"
        SortVnodeMemoryUsedMemory -> "Used memory"
        SortVnodeMemoryPutObjSize -> "Put obj size"
        SortVnodeMemoryDataMemory -> "Data Memory"
        SortVnodeMemoryIndexMemory -> "Index Memory"
        SortVnodeStatusCounter -> "Counter"
        SortVnodeStatusCounterLease -> "Counter lease"
        SortUnsorted -> "None"

stringToSortBy a =
    case a of
        "Name" -> SortName
        "Memory (total)" -> SortMemTotal
        "Memory (Erlang)" -> SortMemErlang
        "Memory (riak)" -> SortMemUsed
        "Uptime" -> SortUptime
        "Tree status" -> SortTtaaeTreeStatus
        "Next rebuild" -> SortTtaaeTreeNextRebuild
        "Last rebuild" -> SortTtaaeTreeLastRebuild
        "Total dirty segments" -> SortTtaaeTreeTotalDirtySegments
        "Ledger cache (# keys)" -> SortVnodeLeveledLedgerCacheSize
        "# active journal files" -> SortVnodeLeveledNActiveJournalFiles
        "Penciller last merge time" -> SortVnodeLeveledPencillerLastMergeTime
        "Journal last compaction time" -> SortVnodeLeveledJournalLastCompactionTime
        "Level files count (Total)" -> SortVnodeLeveledLevelFilesCountTotal
        "GET count" -> SortVnodeLeveledGetCount
        "HEAD count" -> SortVnodeLeveledHeadCount
        "PUT count" -> SortVnodeLeveledPutCount
        "File size" -> SortVnodeLeveldbFilesize
        "Compactions" -> SortVnodeLeveldbCompactions
        "Read MB" -> SortVnodeLeveldbReadMb
        "Write MB" -> SortVnodeLeveldbWriteMb
        "Key count" -> SortVnodeBitcaskKeycount
        "Dead bytes" -> SortVnodeBitcaskDeadbytes
        "Total bytes" -> SortVnodeBitcaskTotalbytes
        "Used memory" -> SortVnodeMemoryUsedMemory
        "Put obj size" -> SortVnodeMemoryPutObjSize
        "Data Memory" -> SortVnodeMemoryDataMemory
        "Index Memory" -> SortVnodeMemoryIndexMemory
        "Counter" -> SortVnodeStatusCounter
        "Counter lease" -> SortVnodeStatusCounterLease
        _ -> SortUnsorted

