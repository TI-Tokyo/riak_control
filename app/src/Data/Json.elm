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

module Data.Json exposing
    ( decodeSshScriptTemplateList
    , decodeSshStoredKeyList
    , decodeSshSession
    , decodeScriptOutput

    , decodeServerInfo

    , decodeCluster
    , decodeClusterActionResult

    , decodeNodeConfig

    , decodeUserList
    , decodeGroupList

    , decodePermissionList

    , decodeTtaaeReport

    , decodeVnodeStatusList
    )

import Data.SshOps exposing (..)
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


-- SshOps ------------------------------

decodeSshStoredKeyList : D.Decoder (List SshKey)
decodeSshStoredKeyList =
    list decodeSshStoredKey

decodeSshStoredKey =
    succeed SshKey
        |> required "name" string
        |> required "body" string
        |> required "created" string


decodeSshScriptTemplateList : D.Decoder (List ScriptTemplate)
decodeSshScriptTemplateList =
    list decodeSshScriptTemplate

decodeSshScriptTemplate =
    let
        tp = succeed TemplateParameter
           |> required "name" string
           |> required "value" string
           |> required "description" string
           |> optional "expert" bool False
    in
        succeed ScriptTemplate
            |> required "name" string
            |> required "body" string
            |> required "params" (list tp)

decodeSshSession =
    succeed SshSession
        |> required "session_id" string

decodeScriptOutput =
    succeed ScriptOutput
        |> required "session_id" string
        |> required "finished" bool
        |> required "output" string


-- Connection ------------------------------

decodeServerInfo : D.Decoder ServerInfo
decodeServerInfo =
    succeed ServerInfo
        |> required "riak_version" string
        |> required "system_version" string
        |> optional "nodename" string ""
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
        |> required "vnodeid" string
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
        |> optional "ledger_cache_size" int -1
        |> optional "n_active_journal_files" int -1
        |> optional "avg_compaction_score" float -1.0
        |> optional "level_files_count" (list countByLevel) []
        |> optional "penciller_inmem_cache_size" int -1
        |> optional "penciller_work_backlog_status" pencillerWorkBacklogStatus {workItems = -1, backlog = False, l0Full = False}
        |> optional "penciller_last_merge_time" string "n/a"
        |> optional "journal_last_compaction_time" string "n/a"
        |> optional "journal_last_compaction_result" journalCompactionResult {filesCompacted = -1, score = -1.0}
        |> optional "get_sample_count" int -1
        |> optional "get_body_time" int -1
        |> optional "head_sample_count" int -1
        |> optional "head_rsp_time" int -1
        |> optional "put_sample_count" int -1
        |> optional "put_prep_time" int -1
        |> optional "put_ink_time" int -1
        |> optional "put_mem_time" int -1
        |> optional "fetch_count_by_level" fetchCountByLevel Vnode.dummyFetchCountByLevel

countByLevel =
    succeed Vnode.CountByLevel
        |> required "level" int
        |> required "count" int

pencillerWorkBacklogStatus =
    succeed Vnode.PencillerWorkBacklogStatus
        |> required "work_items" int
        |> required "backlog" bool
        |> required "l0_full" bool

journalCompactionResult =
    succeed Vnode.JournalCompactionResult
        |> required "files_compacted" int
        |> required "score" float

fetchCountByLevel =
    succeed Vnode.FetchCountByLevel
        |> required "not_found" ctStat
        |> required "mem" ctStat
        |> required "0" ctStat
        |> required "1" ctStat
        |> required "2" ctStat
        |> required "3" ctStat
        |> required "lower" ctStat

ctStat =
    succeed Vnode.CTStat
        |> required "count" int
        |> required "time" int
