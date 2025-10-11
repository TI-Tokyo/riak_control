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

module Data.Vnode exposing (..)

type alias VnodeStatus =
    { idx : String
    , backendStatus : BackendStatus
    , vnodeId : String
    , counter : Int
    , counterLease : Int
    , counterLeaseSize : Int
    , counterLeasing : Bool
    }

type alias BackendStatus =
    { mod : String
    , status : SpecificBackendStatus
    }

type SpecificBackendStatus
    = Leveled LeveledStatus

type alias LeveledStatus =
    { ledgerCacheSize : LedgerCacheSize
    , nActiveJournalFiles : Int
    , avgCompactionScore : Float
    , levelFilesCount : List CountByLevel
    , pencillerInmemCacheSize : Int
    , pencillerWorkBacklogStatus : String
    , pencillerLastMergeTime : String -- Time.Posix
    , journalLastCompactionTime : String -- Time.Posix
    , journalLastCompactionResult : JournalCompactionResult
    , metadataObjsizeRatio : Float
    , recentPutgetheadCounts : List Int
    , recentFetchMeanLevel : Int
    }

type alias LedgerCacheSize =
    { size : Int
    , memory : Int
    }

type alias CountByLevel =
    { level : Int
    , count : Int
    }

type alias JournalCompactionResult =
    { filesCompacted : Int
    , score : Float
    }

type Request
    = GetVnodeStatusAction String PreflistSelection

type PreflistSelection
    = All
    | Specific (List String)

preflistSelectionToStr a =
    case a of
        All -> "all"
        Specific bb -> String.join "," bb
