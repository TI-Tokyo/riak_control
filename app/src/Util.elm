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

module Util exposing (..)

import Data.Security
import Time
import DateTime
import Iso8601
import Regex
import Json.Print


cmp a b =
    if a > b then
        GT
    else
        if a < b then
             LT
         else
             EQ

headAndTail l defaultHd =
    case l of
        a0 :: aa ->
            (a0, aa)
        _ ->
            (defaultHd, [])



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

isGoodExpires a =
    case convertExpires a (Time.millisToPosix 0) of
        Ok _ -> True
        Err _ -> False

convertExpires : String -> Time.Posix -> Result String Data.Security.Expires
convertExpires a now =
    let
        addUp =
            \x ->
                case x of
                    Nothing -> 0
                    Just c ->
                        case (String.slice 0 -1 c, String.right 1 c) of
                            (v, "d") -> 24 * 60 * 60 * (Maybe.withDefault 0 (String.toInt v))
                            (v, "h") -> 60 * 60 * (Maybe.withDefault 0 (String.toInt v))
                            (v, "m") -> 60 * (Maybe.withDefault 0 (String.toInt v))
                            (v, "s") -> Maybe.withDefault 0 (String.toInt v)
                            _ -> 0
    in
        case a of
            "never" ->
                Ok Data.Security.Never
            _ ->
                case Iso8601.toTime a of
                    Ok t -> Ok (Data.Security.On t)
                    Err _ ->
                        let
                            mm = Regex.find
                                 (Maybe.withDefault Regex.never
                                      <| Regex.fromString "in (\\d+d|) *(\\d+h|) *(\\d+m|) *(\\d+s|)") a
                            subm =
                                case List.head mm of
                                    Just k -> k.submatches
                                    Nothing -> []
                        in
                            case subm of
                                [] ->
                                    Err "invalid expires"
                                [Nothing, Nothing, Nothing, Nothing] ->
                                    Err "invalid expires"
                                dhms ->
                                    let
                                        nowSeconds = (Time.posixToMillis now) // 1000
                                        inSeconds = List.foldl (\x q -> q + (addUp x)) 0 dhms
                                    in
                                        Ok <| Data.Security.On <| Time.millisToPosix ((nowSeconds + inSeconds) * 1000)

expiresToString a =
    case a of
        Data.Security.Never -> "never"
        Data.Security.On x -> Iso8601.fromTime x


pprintJson : String -> String
pprintJson a =
    let
        cfg =
            { indent = 4
            , columns = 50
            }
    in
    Result.withDefault "(bad json)" (Json.Print.prettyString cfg a)
