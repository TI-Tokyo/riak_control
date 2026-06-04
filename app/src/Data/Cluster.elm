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

module Data.Cluster exposing (..)

import Data.VersionInfo

type alias Cluster =
    { current : List CurrentMember
    , stagedChanges : List StagedChange
    , planned : List FinalMember
    , transfers : List TransferStats
    , downNodes : List String
    }

type alias CurrentMember =
    { name : String
    , status : CurrentMemberStatus
    , versionInfo : Data.VersionInfo.VersionInfo
    , isMe : Bool
    , reachable : Bool
    , services : List String
    , ringPct : Float
    , pendingPct : Float
    , memTotal : Int
    , memUsed : Int
    , memErlang : Int
    , lowMem : Bool
    , claimant : Bool
    , stagedAction : CurrentMemberStagedAction
    , replacement : Maybe String
    }

type alias StagedChange =
    { name : String
    , action : StageAction
    }


type alias FinalMember =
    { name : String
    , ringPct : Float
    , pendingPct : Float
    }

type alias TransferStats =
    { node : String
    , state : TransferNodeState
    , count : Int
    }

type TransferNodeState
    = WaitingToHandoff
    | Stopped
    | BAD_TRANSFER_NODE_STATE

transferStatsStateFromStr : String -> TransferNodeState
transferStatsStateFromStr a =
    case a of
        "waiting_to_handoff" -> WaitingToHandoff
        "stopped" -> Stopped
        _ -> BAD_TRANSFER_NODE_STATE


emptyCluster : Cluster
emptyCluster =
    { current = []
    , stagedChanges = []
    , planned = []
    , transfers = []
    , downNodes = []
    }


type CurrentMemberStatus
    = Valid
    | Invalid
    | Down
    | Joining
    | Leaving
    | Incompatible
    | Transitioning
    | BAD_CURRENT_MEMBER_STATUS

currentMemberStatusToStr : CurrentMemberStatus -> String
currentMemberStatusToStr a =
    case a of
        Valid -> "valid"
        Invalid -> "invalid"
        Down -> "down"
        Joining -> "joining"
        Leaving -> "leaving"
        Incompatible -> "incompatible"
        Transitioning -> "transitioning"
        BAD_CURRENT_MEMBER_STATUS -> "???"

currentMemberStatusFromStr : String -> CurrentMemberStatus
currentMemberStatusFromStr a =
    case a of
        "valid" -> Valid
        "invalid" -> Invalid
        "down" -> Down
        "leaving" -> Leaving
        "joining" -> Joining
        "incompatible" -> Incompatible
        "transitioning" -> Transitioning
        _ -> BAD_CURRENT_MEMBER_STATUS

type CurrentMemberStagedAction
    = StagedLeave
    | StagedNoChange

currentMemberStagedActionToStr : CurrentMemberStagedAction -> String
currentMemberStagedActionToStr a =
    case a of
        StagedLeave -> "leaving"
        StagedNoChange -> "(no change, not printed)"

currentMemberStagedActionFromStr : String -> CurrentMemberStagedAction
currentMemberStagedActionFromStr a =
    case a of
        "leave" -> StagedLeave
        _ -> StagedNoChange


type StageAction
    = Join
    | Leave
    | Remove
    | Replace
    | ForceReplace
    | BAD_STAGE_ACTION

stageActionToStr : StageAction -> String
stageActionToStr a =
    case a of
        Join -> "join"
        Leave -> "leave"
        Remove -> "remove"
        Replace -> "replace"
        ForceReplace -> "force replace"
        BAD_STAGE_ACTION -> "???"

stageActionFromStr : String -> StageAction
stageActionFromStr a =
    case a of
        "join" -> Join
        "leave" -> Leave
        "remove" -> Remove
        "replace" -> Replace
        "force replace" -> ForceReplace
        _ -> BAD_STAGE_ACTION

type Action
    = GetClusterStatus
    | ClusterPlan PlanAction
    | ClusterConfig ConfigAction

type PlanAction
    = Clear
    | Commit
    | Apply StageChange

type StageChange
    = NodeJoin String
    | NodeLeave String
    | NodeRemove String
    | NodeReplace String String
    | NodeForceReplace String String
    | NodeDown String
    | NodeStop String


type alias ClusterPlanActionResult =
    { result : String }

type alias ConfigResult =
    { result : String }

type ConfigAction
    = GetNodeAppEnv String
    | GetNodeAdvancedConfig String
    | PutNodeAdvancedConfig String String
    | SignalRestart String



type alias RestartingNode =
    { name : String
    , lastUptime : Int
    }
