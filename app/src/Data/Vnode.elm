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

import Dict as Dict

type alias VnodeStatus =
    { idx : String
    , backendStatus : BackendStatus
    , vnodeId : String
    , counter : Int
    , counterLease : Int
    , counterLeaseSize : Int
    , counterLeasing : Bool
    }

type BackendStatus
    = Leveled LeveledStatus
    | Leveldb LeveldbStatus
    | Memory MemoryStatus
    | Bitcask BitcaskStatus
    | Multi MultiStatus
    | PrefixMulti MultiStatus

type alias LeveldbStatus =
    { compactions : Maybe Int
    , filesSizeMb : Maybe Int
    , fixedIndexes : Bool
    , level : Maybe Int
    , readBlockError : String
    , readMb : Maybe Int
    , time : Maybe Int
    , writeMb : Maybe Int
    }

type alias MemoryStatus =
    { putObjSize : Int
    , usedMemory : Int
    , dataTableStatus : EtsTableStatus
    , indexTableStatus : EtsTableStatus
    }

type alias EtsTableStatus =
    { compressed : Bool
    , decentralizedCounters : Bool
    , heir : String
    , id : String
    , keypos : Int
    , memory : Int
    , name : String
    , namedTable : Bool
    , node : String
    , owner : String
    , protection : String
    , readConcurrency : Bool
    , size : Int
    , type_ : String
    , writeConcurrency : Bool
    }

type alias BitcaskStatus =
    { keyCount : Int
    , status : List BitcaskFileStatus
    }

type alias BitcaskFileStatus =
    { filename : String
    , fragmented : Bool
    , deadBytes : Int
    , totalBytes : Int
    }

type alias LeveledStatus =
    { fetchCountByLevel : Maybe FetchCountByLevel
    , getBodyTime : Maybe Int
    , getSampleCount : Int
    , headRspTime : Maybe Int
    , headSampleCount : Int
    , journalLastCompactionDuration : Maybe Int
    , journalLastCompactionMax : Maybe Float
    , journalLastCompactionMean : Maybe Float
    , journalLastCompactionRunlength : Maybe Int
    , journalLastCompactionScore : Maybe Float
    , journalLastCompactionTime : Maybe String
    , ledgerCacheSize : Maybe Int
    , levelFilesCount : List CountByLevel
    , nActiveJournalFiles : Int
    , pencillerInmemCacheSize : Maybe Int
    , pencillerLastMergeTime : Maybe String -- Time.Posix
    , pencillerWorkBacklogStatus : Maybe PencillerWorkBacklogStatus
    , putInkTime : Maybe Int
    , putMemTime : Maybe Int
    , putPrepTime : Maybe Int
    , putSampleCount : Int
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

type alias MultiStatus =
    { backendStatus : Dict.Dict String BackendStatus
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
