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

module Data.Security.Lib exposing
    ( abbreviatePerm
    , convertExpires
    , expiresToString
    , sortUserByExpires
    )

import Util
import Time
import Data.Security exposing (..)
import Regex
import Iso8601

abbreviatePerm : String -> String
abbreviatePerm a =
    case a of
        "cluster_admin" -> "adm"
        "cluster_observer" -> "obs"
        "security" -> "sec"
        _ -> a


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
                    Ok t -> Ok (On t)
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
                                        _ = Debug.log "inSeconds" inSeconds
                                    in
                                        Ok <| On <| Time.millisToPosix ((nowSeconds + inSeconds) * 1000)
expiresToString : Expires -> String
expiresToString a =
    case a of
        Never -> "never"
        On x -> Iso8601.fromTime x

sortUserByExpires : User -> User -> Order
sortUserByExpires a1 a2 =
    case (a1.expires, a2.expires) of
        (Never, Never) -> EQ
        (Never, _) -> GT
        (_, Never) -> LT
        (On t1, On t2) ->
            Util.cmp (Time.posixToMillis t1) (Time.posixToMillis t2)
