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
    | SortMemTotal
    | SortMemErlang
    | SortMemUsed
    | SortUptime
    | SortTtaaeTreeStatus
    | SortTtaaeTreeNextRebuild
    | SortTtaaeTreeLastRebuild
    | SortTtaaeTreeTotalDirtySegments
    | SortVnodeBEStatusLedgerCacheSize
    | SortVnodeBEStatusNActiveJournalFiles
    | SortVnodeBEStatusPencillerLastMergeTime
    | SortVnodeBEStatusJournalLastCompactionTime
    | SortVnodeBEStatusLevelFilesCountTotal
    | SortVnodeBEStatusGetCount
    | SortVnodeBEStatusHeadCount
    | SortVnodeBEStatusPutCount
    | SortVnodeStatusCounter
    | SortVnodeStatusCounterLease
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
        SortVnodeBEStatusLedgerCacheSize -> "Ledger cache (# keys)"
        SortVnodeBEStatusNActiveJournalFiles -> "# active journal files"
        SortVnodeBEStatusPencillerLastMergeTime -> "Penciller last merge time"
        SortVnodeBEStatusJournalLastCompactionTime -> "Journal last compaction time"
        SortVnodeBEStatusLevelFilesCountTotal -> "Level files count (Total)"
        SortVnodeBEStatusGetCount -> "GET count"
        SortVnodeBEStatusHeadCount -> "HEAD count"
        SortVnodeBEStatusPutCount -> "PUT count"
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
        "Ledger cache (# keys)" -> SortVnodeBEStatusLedgerCacheSize
        "# active journal files" -> SortVnodeBEStatusNActiveJournalFiles
        "Penciller last merge time" -> SortVnodeBEStatusPencillerLastMergeTime
        "Journal last compaction time" -> SortVnodeBEStatusJournalLastCompactionTime
        "Level files count (Total)" -> SortVnodeBEStatusLevelFilesCountTotal
        "GET count" -> SortVnodeBEStatusGetCount
        "HEAD count" -> SortVnodeBEStatusHeadCount
        "PUT count" -> SortVnodeBEStatusPutCount
        "Counter" -> SortVnodeStatusCounter
        "Counter lease" -> SortVnodeStatusCounterLease
        _ -> SortUnsorted

