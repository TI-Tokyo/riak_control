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

module Data.User exposing (..)

import Dict exposing (Dict)
import Time


type UserStatus
    = Active
    | Suspended
    | INVALID

type alias User =
    { id : String
    , name : String
    , status : UserStatus
    }


userStatusToString a =
    case a of
        Active -> "active"
        Suspended -> "suspended"
        _ -> "(unknown)"

dummyUser =
    { id = ""
    , name = "-"
    , status = Active
    }
