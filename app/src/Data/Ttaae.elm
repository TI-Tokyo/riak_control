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

module Data.Ttaae exposing (..)

import Dict exposing (Dict)

type TtaaeTreeStatus
    = Empty
    | Partial
    | Built
    | Rebuilding
    | Building
    | BAD_TTAE_TREE_STATUS

type alias TtaaeTree =
    { partition : String
    , isEmpty : Bool
    , status : TtaaeTreeStatus
    , lastRebuild : String
    , nextRebuild : String
    , totalDirtySegments : Int
    , controllerPid : String
    }

type Report
    = Dict String (List TtaaeTree)

ttaeTreeStatusFromStr a =
    case a of
        "empty" -> Empty
        "partial" -> Partial
        "built" -> Built
        "rebuilding" -> Rebuilding
        "building" -> Building
        _ -> BAD_TTAE_TREE_STATUS

ttaeTreeStatusToStr a =
    case a of
        Empty -> "empty"
        Partial -> "partial"
        Built -> "built"
        Rebuilding -> "rebuilding"
        Building -> "building"
        BAD_TTAE_TREE_STATUS -> "???"

compareByTreeStatus f a b =
    case (a |> f |> ttaeTreeStatusToStr) < (b |> f |> ttaeTreeStatusToStr) of
        True -> LT
        False -> GT


type Request
    = GetTtaaeStatusAction String
