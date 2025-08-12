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

module Request.Cluster exposing
    ( getCluster
    , planClear
    , planCommit
    , stageJoin
    , stageLeave
    , stageRemove
    , stageReplace
    , stageForceReplace
    , stageDown
    , stageStop
    )

import Model exposing (Model)
import Data.Json
import Data.Cluster exposing (..)
import Msg exposing (Msg(..))
import Util
import Request.Util exposing (..)

import Http
import HttpBuilder
import HttpBuilder.Task
import Url.Builder
import Json.Encode
import Json.Decode
import Retry
import Task


getCluster : Model -> Cmd Msg
getCluster m =
    let
        url = Url.Builder.crossOrigin m.c.riakNodeUrl [ "cluster" ] []
        task = Http.task
            { url = url
            , method = "get"
            , headers = List.map (\(h, v) -> Http.header h v) (stdHeaders m)
            , body = Http.emptyBody
            , resolver = Http.stringResolver clusterResolver
            , timeout = Nothing
            }
        retryConfig =
            [ Retry.maxDuration 7000
            , Retry.exponentialBackoff { interval = 250, maxInterval = 3000 }
            ]
    in
        task |> Retry.with retryConfig |> Task.attempt GotCluster

clusterResolver a =
    case a of
        Http.GoodStatus_ _ body ->
            case Json.Decode.decodeString Data.Json.decodeCluster body of
                Ok b ->
                    Ok b
                Err err ->
                    Err (Http.BadBody "Bad cluster data")
        Http.BadStatus_ md _ ->
            Err (Http.BadStatus md.statusCode)
        _ ->
            Err (Http.NetworkError)



planClear : Model -> Cmd Msg
planClear m =
    actionRequest m Clear PlanCleared

planCommit : Model -> Cmd Msg
planCommit m =
    actionRequest m Commit PlanCommitted


stageJoin : Model -> String -> Cmd Msg
stageJoin m a =
    actionRequest m (Apply (Data.Cluster.NodeJoin a)) PlanNodeJoined

stageLeave : Model -> String -> Cmd Msg
stageLeave m a =
    actionRequest m (Apply (Data.Cluster.NodeLeave a)) PlanNodeLeft

stageRemove : Model -> String -> Cmd Msg
stageRemove m a =
    actionRequest m (Apply (Data.Cluster.NodeRemove a)) PlanNodeRemoved

stageReplace : Model -> String -> String -> Cmd Msg
stageReplace m a b =
    actionRequest m (Apply (Data.Cluster.NodeReplace a b)) PlanNodeReplaced

stageForceReplace : Model -> String -> String -> Cmd Msg
stageForceReplace m a b =
    actionRequest m (Apply (Data.Cluster.NodeForceReplace a b)) PlanNodeForceReplaced

stageDown : Model -> String -> Cmd Msg
stageDown m a =
    actionRequest m (Apply (Data.Cluster.NodeDown a)) PlanNodeDowned

stageStop : Model -> String -> Cmd Msg
stageStop m a =
    actionRequest m (Apply (Data.Cluster.NodeStop a)) PlanNodeStopped


actionRequest m action msg =
    Url.Builder.crossOrigin m.c.riakNodeUrl [ "cluster" ] []
        |> HttpBuilder.post
        |> HttpBuilder.withJsonBody (clusterActionEncoder action)
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectJson msg Data.Json.decodeClusterActionResult)
        |> HttpBuilder.request

clusterActionEncoder a =
    case a of
        Clear ->
            Json.Encode.object
                [ ("plan", Json.Encode.string "clear") ]
        Commit ->
            Json.Encode.object
                [ ("plan", Json.Encode.string "commit") ]
        Apply (Data.Cluster.NodeJoin b) ->
            Json.Encode.object
                [ ("stage", Json.Encode.object [ ("join", Json.Encode.string b)]) ]
        Apply (Data.Cluster.NodeLeave b) ->
            Json.Encode.object
                [ ("stage", Json.Encode.object [ ("leave", Json.Encode.string b)]) ]
        Apply (Data.Cluster.NodeRemove b) ->
            Json.Encode.object
                [ ("stage", Json.Encode.object [ ("remove", Json.Encode.string b)]) ]
        Apply (Data.Cluster.NodeReplace b c) ->
            Json.Encode.object
                [ ("stage", Json.Encode.object [ ("replace", Json.Encode.string (b++":"++c))]) ]
        Apply (Data.Cluster.NodeForceReplace b c) ->
            Json.Encode.object
                [ ("stage", Json.Encode.object [ ("force_replace", Json.Encode.string (b++":"++c))]) ]
        Apply (Data.Cluster.NodeDown b) ->
            Json.Encode.object
                [ ("node", Json.Encode.object [ ("down", Json.Encode.string b)]) ]
        Apply (Data.Cluster.NodeStop b) ->
            Json.Encode.object
                [ ("node", Json.Encode.object [ ("stop", Json.Encode.string b)]) ]
