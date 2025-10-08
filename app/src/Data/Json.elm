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

module Data.Json exposing
    ( decodeServerInfo

    , decodeCluster
    , decodeClusterActionResult

    , decodeNodeConfig

    , decodeUserList
    , decodeGroupList

    , decodePermissionList

    , decodeTtaaeReport

    , decodeVnodeStatusList
    )

import Data.Server exposing (..)
import Data.Cluster exposing (..)
import Data.Security exposing (..)
import Data.Ttaae as Ttaae
import Data.Vnode as Vnode
import Util

import Json.Decode as D exposing (succeed, list, string, int, float, bool, map, dict, nullable, oneOf, null)
import Json.Decode.Pipeline exposing (required, optional, hardcoded)
import Json.Encode
import Iso8601
import Time
import Dict exposing (Dict)


-- General ------------------------------

decodeServerInfo : D.Decoder ServerInfo
decodeServerInfo =
    succeed ServerInfo
        |> required "riak_version" string
        |> required "system_version" string
        |> required "uptime" int
        |> required "uptime_str" string


-- Cluster ------------------------------

decodeCluster : D.Decoder Cluster
decodeCluster =
    succeed Cluster
        |> required "current_cluster" (list currentMember)
        |> required "staged_changes" (list stagedChange)
        |> required "final_cluster" (list finalMember)
        |> required "transfers" (list transferStats)
        |> required "down_nodes" (list string)


decodeClusterActionResult : D.Decoder ActionResult
decodeClusterActionResult =
    succeed ActionResult
        |> required "result" string

currentMember =
    succeed CurrentMember
        |> required "name" string
        |> required "status" currentMemberStatus
        |> optional "system_info" decodeServerInfo Data.Server.emptyServerInfo
        |> required "is_me" bool
        |> required "reachable" bool
        |> optional "services" (list string) []
        |> optional "ring_pct" float -1
        |> optional "pending_pct" float -1
        |> optional "mem_total" int -1
        |> optional "mem_used" int -1
        |> optional "mem_erlang" int -1
        |> optional "low_mem" bool False
        |> optional "claimant" bool False
        |> optional "staged_action" currentMemberStagedAction StagedNoChange
        |> optional "replacement" (nullable string) Nothing

currentMemberStatus =
    map Data.Cluster.currentMemberStatusFromStr string

currentMemberStagedAction =
    map Data.Cluster.currentMemberStagedActionFromStr string



stagedChange =
    succeed StagedChange
        |> required "name" string
        |> required "action" stageAction

stageAction =
    map Data.Cluster.stageActionFromStr string

finalMember =
    succeed FinalMember
        |> required "name" string
        |> required "ring_pct" float
        |> required "pending_pct" float


transferStats =
    succeed TransferStats
        |> required "node" string
        |> required "state" transferStatsState
        |> required "count" int

transferStatsState =
    map Data.Cluster.transferStatsStateFromStr string


decodeNodeConfig =
    succeed ConfigResult
        |> required "result" string


-- Security ------------------------------

decodeUserList : D.Decoder (List User)
decodeUserList =
    list user

user =
    succeed User
        |> required "name" string
        |> required "groups" (list string)
        |> required "password_hash" string
        |> required "grants" (list grant)
        |> optional "options" (dict string) Dict.empty


decodeGroupList : D.Decoder (List Group)
decodeGroupList =
    list group

group =
    succeed Group
        |> required "name" string
        |> required "grants" (list grant)
        |> optional "options" (dict string) Dict.empty

grant =
    succeed Grant
        |> required "scope" string
        |> required "permissions" (list string)


decodePermissionList : D.Decoder (List String)
decodePermissionList =
    list string


-- TictacAAE
decodeTtaaeReport : D.Decoder (Dict String (List Ttaae.TtaaeTree))
decodeTtaaeReport =
    dict (list ttaaeTree)

ttaaeTree =
    succeed Ttaae.TtaaeTree
        |> required "partition" string
        |> required "status" ttaeTreeStatus
        |> required "last_rebuild" string
        |> required "next_rebuild" string
        |> required "total_dirty_segments" int
        |> required "controller_pid" string

ttaeTreeStatus =
    map Ttaae.ttaeTreeStatusFromStr string


-- Vnode ------------------------------

decodeVnodeStatusList : D.Decoder (List Vnode.VnodeStatus)
decodeVnodeStatusList =
    list vnodeStatus

vnodeStatus =
    succeed Vnode.VnodeStatus
        |> required "idx" string
        |> required "backend_status" backendStatus
        |> required "vnode_id" string
        |> required "counter" int
        |> required "counter_lease" int
        |> required "counter_lease_size" int
        |> required "counter_leasing" bool

backendStatus =
    succeed Vnode.BackendStatus
        |> required "mod" string
        |> required "status" specificBackendStatus

specificBackendStatus =
    oneOf [ map Vnode.Leveled leveledStatus ]

leveledStatus =
    succeed Vnode.LeveledStatus
        |> required "ledger_cache_size" int
        |> required "n_active_journal_files" int
        |> required "avg_compaction_score" float
        |> required "level_files_count" (list countByLevel)
        |> required "penciller_inmem_cache_size" int
        |> required "penciller_work_backlog_status" string
        |> required "penciller_last_merge_time" string
        |> required "journal_last_compaction_time" string
        |> required "journal_last_compaction_result" journalCompactionResult
        |> required "metadata_objsize_ratio" float
        |> required "recent_putgethead_counts" (list int)
        |> required "recent_fetch_mean_level" int

countByLevel =
    succeed Vnode.CountByLevel
        |> required "level" int
        |> required "count" int

journalCompactionResult =
    succeed Vnode.JournalCompactionResult
        |> required "filesCompacted" int
        |> required "score" float
