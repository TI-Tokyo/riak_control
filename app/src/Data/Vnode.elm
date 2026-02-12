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
    | Leveldb LeveldbStatus

type alias LeveldbStatus =
    {}

type alias LeveledStatus =
    { fetchCountByLevel : Maybe FetchCountByLevel
    , getBodyTime : Maybe Int
    , getSampleCount : Maybe Int
    , headRspTime : Maybe Int
    , headSampleCount : Maybe Int
    , journalLastCompactionDuration : Maybe Int
    , journalLastCompactionMax : Maybe Float
    , journalLastCompactionMean : Maybe Float
    , journalLastCompactionRunlength : Maybe Int
    , journalLastCompactionScore : Maybe Float
    , journalLastCompactionTime : Maybe String
    , ledgerCacheSize : Maybe Int
    , levelFilesCount : Maybe (List CountByLevel)
    , nActiveJournalFiles : Maybe Int
    , pencillerInmemCacheSize : Maybe Int
    , pencillerLastMergeTime : Maybe String -- Time.Posix
    , pencillerWorkBacklogStatus : Maybe PencillerWorkBacklogStatus
    , putInkTime : Maybe Int
    , putMemTime : Maybe Int
    , putSampleCount : Maybe Int
    , putPrepTime : Maybe Int
    }

type alias CountByLevel =
    { level : Int
    , count : Int
    }

type alias PencillerWorkBacklogStatus =
    { workItems : Int
    , backlog : Bool
    , l0Full : Bool
    }

type alias FetchCountByLevel =
    { notFound : CTStat
    , mem : CTStat
    , zero : CTStat
    , one : CTStat
    , two : CTStat
    , three : CTStat
    , lower : CTStat
    }

type alias CTStat =
    { count : Int
    , time : Int
    }

dummyFetchCountByLevel =
    { notFound = {count = -1, time = -1}
    , mem = {count = -1, time = -1}
    , zero = {count = -1, time = -1}
    , one = {count = -1, time = -1}
    , two = {count = -1, time = -1}
    , three = {count = -1, time = -1}
    , lower = {count = -1, time = -1}
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
