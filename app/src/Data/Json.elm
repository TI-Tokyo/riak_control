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

    , decodeVersionInfo

    , decodeCluster
    , decodeClusterPlanActionResult

    , decodeNodeConfig

    , decodeUserList
    , decodeGroupList

    , decodePermissionList

    , decodeTtaaeStatus

    , decodeVnodeStatusList
    )

import Data.SshOps exposing (..)
import Data.VersionInfo exposing (..)
import Data.Cluster exposing (..)
import Data.Security exposing (..)
import Data.Ttaae as Ttaae
import Data.Vnode as Vnode
import Util

import Json.Decode as D exposing
    (succeed, fail, list, string, int, float, bool, map, dict, nullable, oneOf, null, at, field, value, andThen)
import Json.Decode.Pipeline exposing (required, requiredAt, optional, hardcoded, custom)
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
            |> required "description" string
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

decodeVersionInfo : D.Decoder (Dict String VersionInfo)
decodeVersionInfo =
    at ["result"] (dict decodeVersionInfoItem)

decodeVersionInfoItem =
    succeed VersionInfo
        |> required "riak_version" string
        |> required "system_version" string
        |> required "uptime" int
        |> required "uptime_str" string


-- Cluster ------------------------------

decodeCluster : D.Decoder Cluster
decodeCluster =
    succeed Cluster
        |> requiredAt ["result", "current_cluster"] (list currentMember)
        |> requiredAt ["result", "staged_changes"] (list stagedChange)
        |> requiredAt ["result", "final_cluster"] (list finalMember)
        |> requiredAt ["result", "transfers"] (list transferStats)
        |> requiredAt ["result", "down_nodes"] (list string)


decodeClusterPlanActionResult : D.Decoder ClusterPlanActionResult
decodeClusterPlanActionResult =
    succeed ClusterPlanActionResult
        |> required "result" string

currentMember =
    succeed CurrentMember
        |> required "name" string
        |> required "status" currentMemberStatus
        |> optional "system_info" decodeSubVersionInfo Data.VersionInfo.emptyVersionInfo
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

decodeSubVersionInfo =
    succeed VersionInfo
        |> required "riak_version" string
        |> required "system_version" string
        |> required "uptime" int
        |> required "uptime_str" string

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
    at ["result"] (list user)

user =
    succeed User
        |> required "name" string
        |> required "created" isoDate
        |> required "modified" isoDate
        |> required "expires" expires
        |> required "groups" (list string)
        |> required "permissions" (list string)
        |> required "auth_method" authMethod
        |> optional "tags" (dict string) Dict.empty

isoDate =
    oneOf
        [ map Time.millisToPosix int
        , Iso8601.decoder
        ]
expires =
    oneOf
        [ map expiresFromInt int
        , at [] string |> andThen maybeNever
        , map On Iso8601.decoder
        , fail "Invalid expires field"
        ]
expiresFromInt a =
    On (Time.millisToPosix a)
maybeNever a =
    case a of
        "never" -> succeed Never
        _ -> fail "not never"
-- permission =
--     map permissionFromString string
-- permissionFromString a =
--     case a of
--         "cluster_admin" -> ClusterAdmin
--         "cluster_observer" -> ClusterObserver
--         "security" -> Security
--         _ -> INVALID_PERMISSION

authMethod =
    map authMethodFromString string
authMethodFromString a =
    case a of
        "password" -> Password
        _ -> INVALID_AUTHMETHOD


decodeGroupList : D.Decoder (List Group)
decodeGroupList =
    at ["result"] (list group)

group =
    succeed Group
        |> required "name" string
        |> required "permissions" (list string)
        |> optional "tags" (dict string) Dict.empty


decodePermissionList : D.Decoder (List String)
decodePermissionList =
    at ["result"] (list string)

-- TictacAAE
decodeTtaaeStatus : D.Decoder (List Ttaae.TtaaeTree)
decodeTtaaeStatus =
    at ["result"] (list ttaaeTree)

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
    at ["result"] (list vnodeStatus)

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
    oneOf [ map Vnode.Bitcask bitcaskStatus
          , map Vnode.Leveled leveledStatus
          , map Vnode.Leveldb leveldbStatus
          , map Vnode.Memory memoryStatus
          , map Vnode.Multi multiStatus
          , map Vnode.PrefixMulti multiStatus
          ]

-- bitcask

bitcaskStatus =
    succeed Vnode.BitcaskStatus
        |> required "key_count" int
        |> required "status" (list bitcaskFileStatus)

bitcaskFileStatus =
    succeed Vnode.BitcaskFileStatus
        |> required "filename" string
        |> required "fragmented" bool
        |> required "dead_bytes" int
        |> required "total_bytes" int

-- leveldb

leveldbStatus =
    succeed Vnode.LeveldbStatus
        |> required "compactions" (nullable int)
        |> required "files_size_mb" (nullable int)
        |> required "fixed_indexes" bool
        |> required "level" (nullable int)
        |> required "read_block_error" string
        |> required "read_mb" (nullable int)
        |> required "time" (nullable int)
        |> required "write_mb" (nullable int)

-- memory

memoryStatus =
    succeed Vnode.MemoryStatus
        |> required "put_obj_size" int
        |> required "used_memory" int
        |> required "data_table_status" etsTableStatus
        |> required "index_table_status" etsTableStatus

etsTableStatus =
    succeed Vnode.EtsTableStatus
        |> required "compressed" bool
        |> required "decentralized_counters" bool
        |> required "heir" string
        |> required "id" string
        |> required "keypos" int
        |> required "memory" int
        |> required "name" string
        |> required "named_table" bool
        |> required "node" string
        |> required "owner" string
        |> required "protection" string
        |> required "read_concurrency" bool
        |> required "size" int
        |> required "type" string
        |> required "write_concurrency" bool

-- leveled

leveledStatus =
    succeed Vnode.LeveledStatus
        |> required "fetch_count_by_level" (nullable fetchCountByLevel)
        |> required "get_body_time" (nullable int)
        |> required "get_sample_count" int
        |> required "head_rsp_time" (nullable int)
        |> required "head_sample_count" int
        |> required "journal_last_compaction_duration" (nullable int)
        |> required "journal_last_compaction_max" (nullable float)
        |> required "journal_last_compaction_mean" (nullable float)
        |> required "journal_last_compaction_runlength" (nullable int)
        |> required "journal_last_compaction_score" (nullable float)
        |> required "journal_last_compaction_time" (nullable string)
        |> required "ledger_cache_size" (nullable int)
        |> required "level_files_count" (list countByLevel)
        |> required "n_active_journal_files" int
        |> required "penciller_inmem_cache_size" (nullable int)
        |> required "penciller_last_merge_time" (nullable string)
        |> required "penciller_work_backlog_status" (nullable pencillerWorkBacklogStatus)
        |> required "put_ink_time" (nullable int)
        |> required "put_mem_time" (nullable int)
        |> required "put_prep_time" (nullable int)
        |> required "put_sample_count" int

countByLevel =
    succeed Vnode.CountByLevel
        |> required "level" int
        |> required "count" int

pencillerWorkBacklogStatus =
    succeed Vnode.PencillerWorkBacklogStatus
        |> required "work_items" int
        |> required "backlog" bool
        |> required "l0_full" bool

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

-- multi

multiStatus =
    succeed Vnode.MultiStatus
        |> required "backend_status" (dict subBackendStatus)

subBackendStatus =
    oneOf [ map Vnode.Bitcask bitcaskStatus
          , map Vnode.Leveled leveledStatus
          , map Vnode.Leveldb leveldbStatus
          , map Vnode.Bitcask bitcaskStatus
          ]
