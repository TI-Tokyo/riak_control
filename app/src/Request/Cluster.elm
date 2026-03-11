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

module Request.Cluster exposing
    ( getClusterStatus
    , planClear
    , planCommit
    , stageJoin
    , stageLeave
    , stageRemove
    , stageReplace
    , stageForceReplace
    , stageDown
    , stageStop

    , getNodeAppEnv
    , getNodeAdvancedConfig
    , putNodeAdvancedConfig

    , signalRestart
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


getClusterStatus : Model -> Cmd Msg
getClusterStatus m =
    let
        url = Url.Builder.crossOrigin m.c.riakNodeUrl [ "ctl" ] []
        task = Http.task
            { url = url
            , method = "post"
            , headers = List.map (\(h, v) -> Http.header h v) (stdHeaders m)
            , body = Http.jsonBody (clusterActionEncoder GetClusterStatus)
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
    clusterPlanActionRequest m (ClusterPlan Clear) PlanCleared

planCommit : Model -> Cmd Msg
planCommit m =
    clusterPlanActionRequest m (ClusterPlan Commit) PlanCommitted


stageJoin : Model -> String -> Cmd Msg
stageJoin m a =
    clusterPlanActionRequest m (ClusterPlan (Apply (Data.Cluster.NodeJoin a))) PlanNodeJoined

stageLeave : Model -> String -> Cmd Msg
stageLeave m a =
    clusterPlanActionRequest m (ClusterPlan (Apply (Data.Cluster.NodeLeave a))) PlanNodeLeft

stageRemove : Model -> String -> Cmd Msg
stageRemove m a =
    clusterPlanActionRequest m (ClusterPlan (Apply (Data.Cluster.NodeRemove a))) PlanNodeRemoved

stageReplace : Model -> String -> String -> Cmd Msg
stageReplace m a b =
    clusterPlanActionRequest m (ClusterPlan (Apply (Data.Cluster.NodeReplace a b))) PlanNodeReplaced

stageForceReplace : Model -> String -> String -> Cmd Msg
stageForceReplace m a b =
    clusterPlanActionRequest m (ClusterPlan (Apply (Data.Cluster.NodeForceReplace a b))) PlanNodeForceReplaced

stageDown : Model -> String -> Cmd Msg
stageDown m a =
    clusterPlanActionRequest m (ClusterPlan (Apply (Data.Cluster.NodeDown a))) PlanNodeDowned

stageStop : Model -> String -> Cmd Msg
stageStop m a =
    clusterPlanActionRequest m (ClusterPlan (Apply (Data.Cluster.NodeStop a))) PlanNodeStopped

getNodeAppEnv : Model -> String -> Cmd Msg
getNodeAppEnv m a =
    Url.Builder.crossOrigin m.c.riakNodeUrl [ "ctl" ] []
        |> HttpBuilder.post
        |> HttpBuilder.withJsonBody (clusterActionEncoder (ClusterConfig (Data.Cluster.GetNodeAppEnv a)))
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectJson GotNodeAppEnv Data.Json.decodeNodeConfig)
        |> HttpBuilder.request

getNodeAdvancedConfig : Model -> String -> Cmd Msg
getNodeAdvancedConfig m a =
    Url.Builder.crossOrigin m.c.riakNodeUrl [ "ctl" ] []
        |> HttpBuilder.post
        |> HttpBuilder.withJsonBody (clusterActionEncoder (ClusterConfig (Data.Cluster.GetNodeAdvancedConfig a)))
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectJson GotNodeAdvancedConfig Data.Json.decodeNodeConfig)
        |> HttpBuilder.request

putNodeAdvancedConfig : Model -> String -> String -> Cmd Msg
putNodeAdvancedConfig m a b =
    Url.Builder.crossOrigin m.c.riakNodeUrl [ "ctl" ] []
        |> HttpBuilder.post
        |> HttpBuilder.withJsonBody (clusterActionEncoder (ClusterConfig (Data.Cluster.PutNodeAdvancedConfig a b)))
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectWhatever PuttedNodeAdvancedConfig)
        |> HttpBuilder.request

signalRestart : Model -> String -> Cmd Msg
signalRestart m a =
    Url.Builder.crossOrigin m.c.riakNodeUrl [ "ctl" ] []
        |> HttpBuilder.post
        |> HttpBuilder.withJsonBody (clusterActionEncoder (ClusterConfig (Data.Cluster.SignalRestart a)))
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectWhatever SignalledNodeRestart)
        |> HttpBuilder.request


clusterPlanActionRequest m action msg =
    Url.Builder.crossOrigin m.c.riakNodeUrl [ "ctl" ] []
        |> HttpBuilder.post
        |> HttpBuilder.withJsonBody (clusterActionEncoder action)
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withExpect (Http.expectJson msg Data.Json.decodeClusterPlanActionResult)
        |> HttpBuilder.request

clusterActionEncoder a =
    case a of
        GetClusterStatus ->
            Json.Encode.object
                [ ("action", Json.Encode.string "GetClusterStatus") ]
        ClusterPlan Clear ->
            Json.Encode.object
                [ ("action", Json.Encode.string "ClearPlan") ]
        ClusterPlan Commit ->
            Json.Encode.object
                [ ("action", Json.Encode.string "CommitPlan") ]
        ClusterPlan (Apply (Data.Cluster.NodeJoin b)) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "StageJoin")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]
        ClusterPlan (Apply (Data.Cluster.NodeLeave b)) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "StageLeave")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]
        ClusterPlan (Apply (Data.Cluster.NodeRemove b)) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "StageRemove")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]
        ClusterPlan (Apply (Data.Cluster.NodeReplace b c)) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "StageReplace")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b)
                                                , ("with", Json.Encode.string c)
                                                ])
                ]
        ClusterPlan (Apply (Data.Cluster.NodeForceReplace b c)) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "StageForceReplace")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b)
                                                , ("with", Json.Encode.string c)
                                                ])
                ]
        ClusterPlan (Apply (Data.Cluster.NodeDown b)) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "DownNode")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]
        ClusterPlan (Apply (Data.Cluster.NodeStop b)) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "StopNode")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]
        ClusterConfig (Data.Cluster.GetNodeAppEnv b) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "GetNodeAppEnv")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]
        ClusterConfig (Data.Cluster.GetNodeAdvancedConfig b) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "GetNodeAdvancedConfig")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b) ])
                ]
        ClusterConfig (Data.Cluster.PutNodeAdvancedConfig b c) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "PutNodeAdvancedConfig")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b)
                                                , ("config", Json.Encode.string c)
                                                ])
                ]
        ClusterConfig (SignalRestart b) ->
            Json.Encode.object
                [ ("action", Json.Encode.string "RestartNode")
                , ("params", Json.Encode.object [ ("node", Json.Encode.string b)
                                                ])
                ]
