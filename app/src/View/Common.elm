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

module View.Common exposing (..)

type SortByField
    = Name
    | MemTotal
    | MemErlang
    | MemUsed
    | Uptime
    | TtaaeTreeStatus
    | TtaaeTreeNextRebuild
    | TtaaeTreeLastRebuild
    | TtaaeTreeTotalDirtySegments
    | Unsorted

type alias SortOrder = Bool

sortOrderText =
    \o -> if o then "Asc" else "Desc"

selectSortByString a =
    case a of
        Name -> "Name"
        MemTotal -> "Memory (total)"
        MemErlang -> "Memory (Erlang)"
        MemUsed -> "Memory (riak)"
        Uptime -> "Uptime"
        TtaaeTreeStatus -> "Tree status"
        TtaaeTreeNextRebuild -> "Next rebuild"
        TtaaeTreeLastRebuild -> "Last rebuild"
        TtaaeTreeTotalDirtySegments -> "Total dirty segments"
        Unsorted -> "None"

stringToSortBy a =
    case a of
        "Name" -> Name
        "Memory (total)" -> MemTotal
        "Memory (Erlang)" -> MemErlang
        "Memory (riak)" -> MemUsed
        "Uptime" -> Uptime
        "Tree status" -> TtaaeTreeStatus
        "Next rebuild" -> TtaaeTreeNextRebuild
        "Last rebuild" -> TtaaeTreeLastRebuild
        "Total dirty segments" -> TtaaeTreeTotalDirtySegments
        _ -> Unsorted

