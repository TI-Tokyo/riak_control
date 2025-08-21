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

    , getNodeConfig
    , putNodeConfig
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

getNodeConfig : Model -> String -> Cmd Msg
getNodeConfig m a =
    Url.Builder.crossOrigin m.c.riakNodeUrl [ "cluster" ] []
        |> HttpBuilder.post
        |> HttpBuilder.withJsonBody (configActionEncoder (Data.Cluster.GetNodeConfig a))
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectJson GotNodeConfig Data.Json.decodeNodeConfig)
        |> HttpBuilder.request

putNodeConfig : Model -> String -> String -> Bool -> Cmd Msg
putNodeConfig m a b c =
    Url.Builder.crossOrigin m.c.riakNodeUrl [ "cluster" ] []
        |> HttpBuilder.post
        |> HttpBuilder.withJsonBody (configActionEncoder (Data.Cluster.PutNodeConfig a b c))
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectWhatever PuttedNodeConfig)
        |> HttpBuilder.request


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
                [ ("action", Json.Encode.string "clear_plan") ]
        Commit ->
            Json.Encode.object
                [ ("action", Json.Encode.string "commit_plan") ]
        Apply (Data.Cluster.NodeJoin b) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "stage_join")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]
        Apply (Data.Cluster.NodeLeave b) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "stage_leave")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]
        Apply (Data.Cluster.NodeRemove b) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "stage_remove")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]
        Apply (Data.Cluster.NodeReplace b c) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "stage_replace")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b)
                                                , ("with", Json.Encode.string c)
                                                ])
                ]
        Apply (Data.Cluster.NodeForceReplace b c) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "stage_force_replace")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b)
                                                , ("with", Json.Encode.string c)
                                                ])
                ]
        Apply (Data.Cluster.NodeDown b) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "down_node")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]
        Apply (Data.Cluster.NodeStop b) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "stop_node")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]

configActionEncoder a =
    case a of
        Data.Cluster.GetNodeConfig b ->
            Json.Encode.object
                [ ("action", Json.Encode.string "get_config")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]
        Data.Cluster.PutNodeConfig b c d ->
            Json.Encode.object
                [ ("action", Json.Encode.string "put_config")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b)
                                                , ("config", Json.Encode.string c)
                                                , ("persist", Json.Encode.bool d)
                                                ])
                ]
