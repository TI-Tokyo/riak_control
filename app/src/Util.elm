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

module Util exposing (..)

import Time
import DateTime
import Iso8601
import Regex
import Json.Print


isoDateToPosix : String -> Time.Posix
isoDateToPosix a =
    case Iso8601.toTime a of
        Ok s -> s
        Err _ -> Time.millisToPosix 0


ellipsize : String -> Int -> String
ellipsize a n =
    if String.length a > n then
        (String.left n a) ++ "…"
    else
        a


compareByPosixTime f a b =
    case (a |> f |> Time.posixToMillis) < (b |> f |> Time.posixToMillis) of
        True -> LT
        False -> GT

subtract : List a -> List a -> List a
subtract l1 l2 =
    List.filter (\a -> not (List.member a l2)) l1

addOrDeleteElement : List a -> a -> List a
addOrDeleteElement l a =
    if List.member a l then
        delElement l a
    else
        a :: l

delElement l a =
    List.filter (\x -> x /= a) l

isGoodPassword a =
    7 < String.length a



pprintJson : String -> String
pprintJson a =
    let
        cfg =
            { indent = 4
            , columns = 50
            }
    in
    Result.withDefault "(bad json)" (Json.Print.prettyString cfg a)
