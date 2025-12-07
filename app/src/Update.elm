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

module Update exposing
    ( update
    , refreshAll
    )

import Model exposing (..)
import Msg exposing (Msg(..))
import Request.SshOps
import Request.Admin
import Request.Cluster
import Request.Security
import Request.Ttaae
import Request.Vnode
import Data.SshOps
import Data.Server
import Data.Cluster exposing (emptyCluster)
import Data.Security exposing (dummyUser, dummyGroup)
import Data.Ttaae
import Data.Vnode
import Data.Json
import View.Common
import Util

import Time
import Task exposing (attempt, perform, andThen, succeed, sequence)
import Platform.Cmd
import Dict exposing (Dict)
import Json.Decode
import Http
import Process
import Material.Snackbar as Snackbar


update : Msg -> Model -> (Model, Cmd Msg)
update msg m =
    case msg of
        TabClicked t ->
            let s_ = m.s in
            ( {m | s = {s_ | activeTab = t, topDrawerOpen = False}}
            , refreshTabMsg m t
            )
        OpenTopDrawer ->
            let s_ = m.s in
            ( {m | s = {s_ | topDrawerOpen = not s_.topDrawerOpen}}
            , Cmd.none
            )

        -- SshOps
        ------------------------------
        RefreshBootOptions ->
            (m, Cmd.batch [ Request.SshOps.listSshScriptTemplates m
                          , Request.SshOps.listSshStoredKeys m
                          ])
        GetSshScriptTemplateList ->
            (m, Request.SshOps.listSshScriptTemplates m)
        GotSshScriptTemplateList (Ok aa) ->
            let s_ = m.s in
            ({m | s = {s_ | sshScriptTemplateSpecs = aa}}, Cmd.none)
        GotSshScriptTemplateList (Err err) ->
            ( handleHttpError m "Failed to get a list of script templates: " err
            , Cmd.none
            )

        GetSshKeyList ->
            (m, Request.SshOps.listSshStoredKeys m)
        GotSshKeyList (Ok aa) ->
            let s_ = m.s in
            ({m | s = {s_ | sshStoredKeys = aa}}, Cmd.none)
        GotSshKeyList (Err err) ->
            ( handleHttpError m "Failed to get a list of stored ssh keys: " err
            , Cmd.none
            )

        StoreSshKey ->
            let
                pp = { name = m.s.sshNewKeyName
                     , body = m.s.sshNewKeyBody
                     }
            in
                (m, Request.SshOps.storeSshKey m pp)
        SshKeyStored (Ok ()) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Stored ssh key " ++ m.s.sshNewKeyName)) m.s.msgQueue}}
            , Cmd.none
            )
        SshKeyStored (Err err) ->
            ( handleHttpError m "Failed to store ssh key: " err
            , Cmd.none
            )

        DeleteSshKey ->
            let
                pp = { name = m.s.sshKeyNameToDelete }
            in
                (m, Request.SshOps.deleteSshKey m pp)
        SshKeyDeleted (Ok ()) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Deleted ssh key " ++ m.s.sshKeyNameToDelete)) m.s.msgQueue}}
            , Cmd.none
            )
        SshKeyDeleted (Err err) ->
            ( handleHttpError m "Failed to delete ssh key: " err
            , Cmd.none
            )

        ShowAddSshKeyDialog ->
            let s_ = m.s in
            ({m | s = {s_ | sshAddKeyDialogShown = True}}, Cmd.none)
        SshNewKeyNameChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | sshNewKeyName = a}}, Cmd.none)
        SshNewKeyBodyChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | sshNewKeyBody = a}}, Cmd.none)
        SshAddKeyDialogCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | sshAddKeyDialogShown = False}}, Cmd.none)
        SshAddKeyDialogConfirmed ->
            let
                s_ = m.s
                pp = { name = m.s.sshNewKeyName, body = m.s.sshNewKeyBody }
            in
                ({m | s = {s_ | sshAddKeyDialogShown = False}}, Request.SshOps.storeSshKey m pp)

        ShowDeleteSshKeyDialog ->
            let s_ = m.s in
            ({m | s = {s_ | sshDeleteKeyDialogShown = True}}, Cmd.none)
        SshKeyNameForDeletionChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | sshKeyNameToDelete = a}}, Cmd.none)

        SshDeleteKeyDialogCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | sshDeleteKeyDialogShown = False}}, Cmd.none)

        SshDeleteKeyDialogConfirmed ->
            let
                s_ = m.s
                pp = { name = m.s.sshNewKeyName }
            in
                ({m | s = {s_ | sshAddKeyDialogShown = False}}, Request.SshOps.deleteSshKey m pp)

        SshSelectedScriptTemplateNameForExecChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | sshSelectedScriptTemplateName = a}}, Cmd.none)

        SshTargetHostsChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | sshTargetHostsStr = a}}, Cmd.none)

        SshScriptTemplateParamChanged a s ->
            let
                s_ = m.s
                f = \{name, value} -> if name == a then {name = name, value = s} else {name = name, value = value}
                pp = List.map f m.s.sshScriptTemplateParams
            in
                ({m | s = {s_ | sshScriptTemplateParams = pp}}, Cmd.none)

        ExecSshScript ->
            let
                pp = { hosts = Data.SshOps.targetHostsFromStr m.s.sshTargetHostsStr
                     , scriptTemplateName = m.s.sshSelectedScriptTemplateName
                     , scriptTemplateParams = m.s.sshScriptTemplateParams
                     }
            in
                (m, Request.SshOps.execSshScript m pp)
        SshScriptExecuted (Ok ()) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Script executed")) m.s.msgQueue}}
            , Cmd.none
            )
        SshScriptExecuted (Err err) ->
            ( handleHttpError m "Failed to execute script: " err
            , Cmd.none
            )

        -- Connection
        ------------------------------
        Ping ->
            let
                task =
                    Time.now
                        |> andThen
                           (\t0 ->
                                Request.Admin.pingTask m
                                    |> andThen
                                        (\_ ->
                                             Time.now
                                                 |> andThen
                                                      (\t1 ->
                                                           (Time.posixToMillis t1) - (Time.posixToMillis t0)
                                                               |> succeed
                                                      )
                                        )
                           )
            in
                (m, attempt TimedPong task)
        TimedPong (Ok a) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Ping response: OK in " ++ (String.fromInt a) ++ " msec")) m.s.msgQueue}}
            , Cmd.none
            )
        TimedPong (Err err) ->
            ( handleHttpError m "Failed to ping riak: " err
            , Cmd.none
            )

        GetServerInfo ->
            (m, Request.Admin.getServerInfo m)
        GotServerInfo (Ok a) ->
            let
                s_ = m.s
            in
                ({m | s = {s_ | serverInfo = a}}, Cmd.none)
        GotServerInfo (Err err) ->
            ( handleHttpError m "Failed to get server info: " err
            , Cmd.none
            )


        -- Admin creds
        ------------------------------
        ShowConfigDialog ->
            let s_ = m.s in
            ({m | s = {s_ | configDialogShown = True}}, Cmd.none)
        ConfigRiakNodeUrlChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigRiakNodeUrl = s}}, Cmd.none)
        ConfigRiakAdminUserChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigRiakAdminUser = s}}, Cmd.none)
        ConfigRiakAdminPasswordChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigRiakAdminPassword = s}}, Cmd.none)
        SetConfig ->
            let
                c_ = m.c
                s_ = m.s
            in
                ( { m | c = {c_ | riakNodeUrl = m.s.newConfigRiakNodeUrl
                                , riakAdminUser = m.s.newConfigRiakAdminUser
                                , riakAdminPassword = m.s.newConfigRiakAdminPassword
                            },
                        s = {s_ | configDialogShown = False}
                  }
                , Cmd.none
                )
        SetConfigCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | configDialogShown = False}}, Cmd.none)


        -- Cluster
        ------------------------------
        GetCluster ->
            (m, Request.Cluster.getCluster m)
        GotCluster (Ok a) ->
            let
                s_ = m.s
                prevT = s_.ttaaeReportShownForNode
                prevV = s_.vnodeStatusShownForNode
                thisNode = connectedNode a
            in
                ( {m | s = {s_ | cluster = a
                               , notReadyMessage = ""
                               , ttaaeReportShownForNode = if prevT == "" then thisNode else prevT
                               , vnodeStatusShownForNode = if prevV == "" then thisNode else prevV
                               }
                  }
                , Cmd.none
                )
        GotCluster (Err (Http.BadStatus 425)) ->
            let s_ = m.s in
            ({m | s = {s_ | cluster = Data.Cluster.emptyCluster
                          , notReadyMessage = "ring not ready"}}
            , Cmd.none
            )
        GotCluster (Err err) ->
            let s_ = m.s in
            ({m | s = {s_ | cluster = Data.Cluster.emptyCluster
                          , notReadyMessage = explainHttpError err}}
            , Cmd.none
            )

        ClusterMemberSortByFieldChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | clusterMemberSortBy = View.Common.stringToSortBy s}}, Cmd.none)
        ClusterMemberSortOrderChanged ->
            let s_ = m.s in
            ({m | s = {s_ | clusterMemberSortOrder = not s_.clusterMemberSortOrder}}, Cmd.none)

        NewClusterNodeChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newNodeToJoin = s}}, Cmd.none)


        PlanClear ->
            let s_ = m.s in
            ({m | s = s_}, Request.Cluster.planClear m)
        PlanCleared (Ok _) ->
            (m, refreshCluster)
        PlanCleared (Err err) ->
            ( handleHttpError m "Failed to clear plan: " err
            , Cmd.none
            )

        PlanCommit ->
            let s_ = m.s in
            ({m | s = s_}, Request.Cluster.planCommit m)
        PlanCommitted (Ok _) ->
            (m, refreshCluster)
        PlanCommitted (Err err) ->
            ( handleHttpError m "Failed to commit plan: " err
            , Cmd.none
            )

        -- Nodes
        ShowAddNodeDialog ->
            let s_ = m.s in
            ({m | s = {s_ | addNodeDialogShown = True}}, Cmd.none)
        AddNodeDialogCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | addNodeDialogShown = False}}, Cmd.none)
        PlanNodeJoin ->
            let s_ = m.s in
            ({m | s = {s_ | newNodeToJoin = ""}}, Request.Cluster.stageJoin m m.s.newNodeToJoin)
        PlanNodeJoined (Ok r) ->
            let
                s_ = m.s
                m_ = {m | s = {s_ | newNodeToJoin = ""}}
            in
                handleClusterActionResult m_ "staging join" r.result
        PlanNodeJoined (Err (Http.BadStatus 412)) ->
            handleClusterActionResult m "staging join" "node is down"
        PlanNodeJoined (Err err) ->
            ( handleHttpError m "Failed to stage node join: " err
            , Cmd.none
            )

        NodeMenuOpen a ->
            let s_ = m.s in
            ({m | s = {s_ | nodeMenuOpenedFor = a}}, Cmd.none)
        NodeMenuClose ->
            let s_ = m.s in
            ({m | s = {s_ | nodeMenuOpenedFor = ""}}, Cmd.none)

        PlanNodeLeave a ->
            let s_ = m.s in
            ({m | s = {s_ | nodeMenuOpenedFor = ""}}, Request.Cluster.stageLeave m a)
        PlanNodeLeft (Ok r) ->
            handleClusterActionResult m "staging node leave" r.result
        PlanNodeLeft (Err err) ->
            ( handleHttpError m "Failed to stage node leave: " err
            , Cmd.none
            )

        PlanNodeRemove a ->
            let s_ = m.s in
            ({m | s = {s_ | nodeMenuOpenedFor = ""}}, Request.Cluster.stageRemove m a)
        PlanNodeRemoved (Ok r) ->
            handleClusterActionResult m "staging node remove" r.result
        PlanNodeRemoved (Err err) ->
            ( handleHttpError m "Failed to stage node remove: " err
            , Cmd.none
            )

        AskPlanNodeReplace a ->
            let s_ = m.s in
            ({m | s = {s_ | nodeMenuOpenedFor = ""
                          , replaceDialogShownFor = a
                          , replaceNodeWith = ""}}, Cmd.none)
        PlanNodeReplaceWithChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | replaceNodeWith = a}}, Cmd.none)
        PlanNodeReplaceDialogConfirmed ->
            let s_ = m.s in
            ( {m | s = {s_ | replaceDialogShownFor = ""
                           , replaceNodeWith = ""}}
            , perform (\_ -> PlanNodeReplace s_.replaceDialogShownFor s_.replaceNodeWith) Time.now
            )
        PlanNodeReplaceDialogCancelled ->
            let s_ = m.s in
            ( {m | s = {s_ | replaceDialogShownFor = ""
                           , replaceNodeWith = ""}}
            , Cmd.none
            )
        PlanNodeReplace a b ->
            let s_ = m.s in
            ({m | s = {s_ | nodeMenuOpenedFor = ""}}, Request.Cluster.stageReplace m a b)
        PlanNodeReplaced (Ok r) ->
            handleClusterActionResult m "staging node replace" r.result
        PlanNodeReplaced (Err err) ->
            ( handleHttpError m "Failed to stage node replace: " err
            , Cmd.none
            )

        AskPlanNodeForceReplace a ->
            let s_ = m.s in
            ({m | s = {s_ | nodeMenuOpenedFor = ""
                          , forceReplaceDialogShownFor = a
                          , replaceNodeWith = ""}}, Cmd.none)
        PlanNodeForceReplaceDialogConfirmed ->
            let s_ = m.s in
            ( {m | s = {s_ | forceReplaceDialogShownFor = ""
                           , replaceNodeWith = ""}}
            , perform (\_ -> PlanNodeForceReplace s_.forceReplaceDialogShownFor s_.replaceNodeWith) Time.now
            )
        PlanNodeForceReplaceDialogCancelled ->
            let s_ = m.s in
            ( {m | s = {s_ | forceReplaceDialogShownFor = ""
                           , replaceNodeWith = ""}}
            , Cmd.none
            )
        PlanNodeForceReplace a b ->
            let s_ = m.s in
            ({m | s = {s_ | nodeMenuOpenedFor = ""}}, Request.Cluster.stageForceReplace m a b)
        PlanNodeForceReplaced (Ok r) ->
            handleClusterActionResult m "staging node force replace" r.result
        PlanNodeForceReplaced (Err err) ->
            ( handleHttpError m "Failed to stage node force_replace: " err
            , Cmd.none
            )

        PlanNodeDown a ->
            let s_ = m.s in
            ({m | s = {s_ | nodeMenuOpenedFor = ""}}, Request.Cluster.stageDown m a)
        PlanNodeDowned (Ok r) ->
            handleClusterActionResult m "staging node down" r.result
        PlanNodeDowned (Err err) ->
            ( handleHttpError m "Failed to stage node down: " err
            , Cmd.none
            )

        PlanNodeStop a ->
            let s_ = m.s in
            ({m | s = {s_ | nodeMenuOpenedFor = ""}}, Request.Cluster.stageStop m a)
        PlanNodeStopped (Ok r) ->
            handleClusterActionResult m "staging node stop" r.result
        PlanNodeStopped (Err err) ->
            ( handleHttpError m "Failed to stage node stop: " err
            , Cmd.none
            )

        GetNodeAppEnv a ->
            (m, Request.Cluster.getNodeAppEnv m a)
        GotNodeAppEnv (Ok r) ->
            let
                s_ = m.s
                newNodeAppEnvs = Dict.insert s_.nodeMenuOpenedFor r.result s_.nodeAppEnvs
            in
                ( {m | s = {s_ | nodeMenuOpenedFor = ""
                               , nodeAppEnvs = newNodeAppEnvs
                               , nodeAppEnvShownFor = Just s_.nodeMenuOpenedFor}}
                , Cmd.none
                )
        GotNodeAppEnv (Err err) ->
            ( handleHttpError m "Failed to get node app envs: " err
            , Cmd.none
            )
        NodeAppEnvDialogDismissed ->
            let s_ = m.s in
            ({m | s = {s_ | nodeAppEnvShownFor = Nothing}}, Cmd.none)


        GetNodeAdvancedConfig a ->
            (m, Request.Cluster.getNodeAdvancedConfig m a)
        GotNodeAdvancedConfig (Ok r) ->
            let
                s_ = m.s
                newNodeAdvancedConfigs = Dict.insert s_.nodeMenuOpenedFor r.result s_.nodeAdvancedConfigs
            in
                ( {m | s = {s_ | nodeMenuOpenedFor = ""
                               , nodeAdvancedConfigs = newNodeAdvancedConfigs
                               , nodeAdvancedConfigShownFor = Just s_.nodeMenuOpenedFor}}
                , Cmd.none
                )
        GotNodeAdvancedConfig (Err err) ->
            ( handleHttpError m "Failed to get node advanced.config: " err
            , Cmd.none
            )

        PutNodeAdvancedConfig a b ->
            (m, Request.Cluster.putNodeAdvancedConfig m a b)
        PuttedNodeAdvancedConfig (Ok ()) ->
            let s_ = m.s in
            ( {m | s = {s_ | nodeMenuOpenedFor = ""
                           , nodeAdvancedConfigShownFor = Nothing}}
            , Cmd.none
            )
        PuttedNodeAdvancedConfig (Err err) ->
            ( handleHttpError m "Failed to put node advanced.config: " err
            , Cmd.none
            )

        NodeAdvancedConfigChanged a ->
            let
                s_ = m.s
                n = s_.nodeAdvancedConfigShownFor |> Maybe.withDefault ""
            in
                ({m | s = {s_ | nodeAdvancedConfigs = Dict.insert n a s_.nodeAdvancedConfigs}}, Cmd.none)
        NodeAdvancedConfigDialogConfirmed ->
            let
                s_ = m.s
                node = Maybe.withDefault "" m.s.nodeAdvancedConfigShownFor
                cfg = Maybe.withDefault "" (Dict.get node m.s.nodeAdvancedConfigs)
            in
                ( {m | s = {s_ | nodeAdvancedConfigShownFor = Nothing}}
                , perform (\_ -> PutNodeAdvancedConfig node cfg)
                    Time.now
                )
        NodeAdvancedConfigDialogCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | nodeAdvancedConfigShownFor = Nothing}}, Cmd.none)

        SignalNodeRestart a ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Restarting " ++ a)) m.s.msgQueue}}
            , Request.Cluster.signalRestart m a
            )
        SignalledNodeRestart (Ok ()) ->
            (m, Cmd.none)
        SignalledNodeRestart (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to signal node restart: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        PromptBeginRollingRestart ->
            let s_ = m.s in
            ( {m | s = {s_ | rollingRestartRequestShown = True}}
            , Cmd.none
            )
        BeginRollingRestartConfirmed ->
            let s_ = m.s in
            ( {m | s = {s_ | rollingRestartRequestShown = False}}
            , perform (\_ -> BeginRollingRestart) Time.now
            )
        BeginRollingRestartCancelled ->
            let s_ = m.s in
            ( {m | s = {s_ | rollingRestartRequestShown = False}}
            , Cmd.none
            )
        BeginRollingRestart ->
            let
                s_ = m.s
                claimantLast = (\a b -> if a.claimant then GT else LT)
                rp = s_.cluster.current
                   |> List.sortWith claimantLast
                   |> List.map (\{name, systemInfo} -> { name = name
                                                       , lastUptime = systemInfo.uptime
                                                       })
            in
                ( {m | s = {s_ | nodeBeingRestartedNow = Nothing
                               , rollingRestartQueue = rp}}
                , perform (\_ -> AttemptNodeRestart) Time.now
                )

        AttemptNodeRestart ->
            let s_ = m.s in
            if s_.rollingRestartQueue == [] then
                ( {m | s = {s_ | nodeBeingRestartedNow = Nothing
                               , msgQueue = Snackbar.addMessage
                                     (Snackbar.message ("rolling restart completed")) m.s.msgQueue}}
                , Cmd.none
                )
            else
                if Model.clusterIsStable m then
                    let
                        (n0, nn) = Util.headAndTail s_.rollingRestartQueue {name = "", lastUptime = 0}
                    in
                        ( {m | s = {s_ | rollingRestartQueue = nn
                                       , nodeBeingRestartedNow = Just n0}}
                        , Cmd.batch [ perform (\_ -> SignalNodeRestart n0.name) Time.now
                                    , perform (\_ -> WaitForNode n0) (Process.sleep 5000
                                                                     |> andThen (\_ -> Time.now))
                                    ]
                        )
                else
                    ( m
                    , perform (\_ -> AttemptNodeRestart) (Process.sleep 5000
                                                         |> andThen (\_ -> Time.now))
                    )
        WaitForNode n ->
            let
                currentUptime =
                    case Model.nodeBy m .name n.name of
                        Nothing ->
                            -1
                        Just cm ->
                            cm.systemInfo.uptime
            in
                if currentUptime /= -1 && currentUptime < n.lastUptime then
                    (m, perform (\_ -> AttemptNodeRestart) Time.now)
                else
                    (m, perform (\_ -> WaitForNode n) (Process.sleep 5000 |> andThen (\_ -> Time.now)))


        -- TictacAAE
        ------------------------------
        GetTtaaeReport ->
            (m, Request.Ttaae.getReport m m.s.ttaaeReportShownForNode)
        GotTtaaeReport (Ok r) ->
            let s_ = m.s in
            ({m | s = {s_ | ttaaeReport = r}}, Cmd.none)
        GotTtaaeReport (Err err) ->
            ( handleHttpError m "Failed to get ttaae report: " err
            , Cmd.none
            )

        TtaaeTreeSortByFieldChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | ttaaeTreeSortBy = View.Common.stringToSortBy a}}, Cmd.none)
        TtaaeTreeSortOrderChanged ->
            let s_ = m.s in
            ({m | s = {s_ | ttaaeTreeSortOrder = not s_.ttaaeTreeSortOrder}}, Cmd.none)

        TtaaeTreeShowForNodeChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | ttaaeReportShownForNode = a}}, Request.Ttaae.getReport m a)


        -- Vnode
        ------------------------------
        GetVnodeStatus ->
            (m, Request.Vnode.getVnodeStatus m m.s.vnodeStatusShownForNode)
        GotVnodeStatus (Ok r) ->
            let
                s_ = m.s
                prevVnodeStatus = s_.vnodeStatus
            in
                ( {m | s = {s_ | vnodeStatus = Dict.insert s_.vnodeStatusShownForNode r prevVnodeStatus}}
                , Cmd.none
                )
        GotVnodeStatus (Err err) ->
            ( handleHttpError m "Failed to get vnode status: " err
            , Cmd.none
            )

        VnodeStatusSortByFieldChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | vnodeStatusSortBy = View.Common.stringToSortBy a}}, Cmd.none)
        VnodeStatusSortOrderChanged ->
            let s_ = m.s in
            ({m | s = {s_ | vnodeStatusSortOrder = not s_.vnodeStatusSortOrder}}, Cmd.none)

        VnodeStatusShowForNodeChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | vnodeStatusShownForNode = a}}, Request.Vnode.getVnodeStatus m a)


        -- User
        ------------------------------
        UserFilterChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | userFilterValue = s}}, Cmd.none)
        UserFilterInItemClicked s ->
            let s_ = m.s in
            ({m | s = {s_ | userFilterIn = Util.addOrDeleteElement s_.userFilterIn s}}, Cmd.none)
        UserSortByFieldChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | userSortBy = View.Common.stringToSortBy s}}, Cmd.none)
        UserSortOrderChanged ->
            let s_ = m.s in
            ({m | s = {s_ | userSortOrder = not s_.userSortOrder}}, Cmd.none)

        ListUsers ->
            (m, Request.Security.listUsers m)
        GotUserList (Ok users) ->
            let s_ = m.s in
            ({m | s = { s_ | users = users}}, Cmd.none)
        GotUserList (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | users = [], msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to fetch users: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        ShowCreateUserDialog ->
            let s_ = m.s in
            ({m | s = {s_ | createUserDialogShown = True}}, Cmd.none)
        NewUserNameChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | newUserName = a}}, Cmd.none)
        NewUserPasswordChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | newUserPassword = a}}, Cmd.none)
        CreateUser ->
            (m, Request.Security.createUser m)
        CreateUserCancelled ->
            (resetCreateUserDialogFields m, Cmd.none)
        UserCreated (Ok ()) ->
            (resetCreateUserDialogFields m, Cmd.batch [ Request.Security.listUsers m
                                                      ])
        UserCreated (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to create user: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        DeleteUser a ->
            let s_ = m.s in
            ( {m | s = {s_ | confirmDeleteUserDialogShownFor = Just a}}, Cmd.none )
        DeleteUserConfirmed ->
            let
                s_ = m.s
                a = Maybe.withDefault "" m.s.confirmDeleteUserDialogShownFor
            in
                ( {m | s = {s_ | confirmDeleteUserDialogShownFor = Nothing}}
                , Request.Security.deleteUser m a
                )
        DeleteUserNotConfirmed ->
            let s_ = m.s in
            ( {m | s = {s_ | confirmDeleteUserDialogShownFor = Nothing}}, Cmd.none )
        UserDeleted (Ok ()) ->
            (m, Request.Security.listUsers m)
        UserDeleted (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to delete user: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        ShowEditUserDialog a ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserDialogFor = Just a}}, Cmd.none)
        UpdateUser ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserDialogFor = Nothing}}, Request.Security.updateUser m)
        EditUserCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserDialogFor = Nothing}}, Cmd.none)


        ShowEditUserGroupsDialog a ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserGroupsDialogFor = Just a}}, Cmd.none)
        EditUserGroupsCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | openEditUserGroupsDialogFor = Nothing}}, Cmd.none)


        ShowAddUserGroupDialog a ->
            let s_ = m.s in
            ({m | s = {s_ | openAddUserGroupsDialogFor = Just a}}, Cmd.none)
        AddUserGroupDialogCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | openAddUserGroupsDialogFor = Nothing}}, Cmd.none)
        SelectOrUnselectUserGroupToAdd a ->
            let s_ = m.s in
            ({m | s = {s_ | selectedUserGroupsForAdd = Util.addOrDeleteElement s_.selectedUserGroupsForAdd a}}
            , Cmd.none
            )
        SelectOrUnselectUserGroupToDelete a ->
            let s_ = m.s in
            ({m | s = {s_ | selectedUserGroupsForDelete = Util.addOrDeleteElement s_.selectedUserGroupsForDelete a}}
            , Cmd.none
            )

        AddUserGroupBatch ->
            let s_ = m.s in
            ( {m | s = { s_
                       | openAddUserGroupsDialogFor = Nothing
                       , selectedUserGroupsForAdd = []
                       , selectedUserGroupsForDelete = []}}
            , Cmd.batch (List.map (Request.Security.addUserGroup m) s_.selectedUserGroupsForAdd)
            )
        DeleteUserGroupBatch ->
            let s_ = m.s in
            ( {m | s = { s_
                       | selectedUserGroupsForAdd = []
                       , selectedUserGroupsForDelete = []}}
            , Cmd.batch (List.map (Request.Security.deleteUserGroup m) s_.selectedUserGroupsForDelete)
            )

        UserGroupAdded _ ->
            (m, Request.Security.listUsers m)
        UserGroupDeleted _ ->
            (m, Request.Security.listUsers m)

        UserGrantAdded _ ->
            (m, Request.Security.listUsers m)
        UserGrantDeleted _ ->
            (m, Request.Security.listUsers m)


        -- Group
        ------------------------------
        GroupFilterChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | groupFilterValue = s}}, Cmd.none)
        GroupFilterInItemClicked s ->
            let s_ = m.s in
            ({m | s = {s_ | groupFilterIn = Util.addOrDeleteElement s_.groupFilterIn s}}, Cmd.none)
        GroupSortByFieldChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | groupSortBy = View.Common.stringToSortBy s}}, Cmd.none)
        GroupSortOrderChanged ->
            let s_ = m.s in
            ({m | s = {s_ | groupSortOrder = not s_.groupSortOrder}}, Cmd.none)

        ListGroups ->
            (m, Request.Security.listGroups m)
        GotGroupList (Ok groups) ->
            let s_ = m.s in
            ({m | s = { s_ | groups = groups}}, Cmd.none)
        GotGroupList (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | groups = [], msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to fetch groups: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        ShowCreateGroupDialog ->
            let s_ = m.s in
            ({m | s = {s_ | createGroupDialogShown = True}}, Cmd.none)
        NewGroupNameChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | newGroupName = a}}, Cmd.none)
        CreateGroup ->
            (m, Request.Security.createGroup m)
        CreateGroupCancelled ->
            (resetCreateGroupDialogFields m, Cmd.none)
        GroupCreated (Ok ()) ->
            (resetCreateGroupDialogFields m, Cmd.batch [ Request.Security.listGroups m
                                                      ])
        GroupCreated (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to create group: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        DeleteGroup a ->
            let s_ = m.s in
            ( {m | s = {s_ | confirmDeleteGroupDialogShownFor = Just a}}, Cmd.none )
        DeleteGroupConfirmed ->
            let
                s_ = m.s
                a = Maybe.withDefault "" m.s.confirmDeleteGroupDialogShownFor
            in
                ( {m | s = {s_ | confirmDeleteGroupDialogShownFor = Nothing}}
                , Request.Security.deleteGroup m a
                )
        DeleteGroupNotConfirmed ->
            let s_ = m.s in
            ( {m | s = {s_ | confirmDeleteGroupDialogShownFor = Nothing}}, Cmd.none )
        GroupDeleted (Ok ()) ->
            (m, Request.Security.listGroups m)
        GroupDeleted (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to delete group: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        ShowEditGroupDialog u ->
            let s_ = m.s in
            ({m | s = {s_ | openEditGroupDialogFor = Just u}}, Cmd.none)
        UpdateGroup ->
            let s_ = m.s in
            ({m | s = {s_ | openEditGroupDialogFor = Nothing}}, Request.Security.updateGroup m)
        EditGroupCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | openEditGroupDialogFor = Nothing}}, Cmd.none)

        -- Group/User shared
        ShowEditGrantsDialog a ->
            let s_ = m.s in
            ({m | s = {s_ | openEditGrantsDialogFor = Just a}}, Cmd.none)
        EditGrantsCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | openEditGrantsDialogFor = Nothing}}, Cmd.none)


        ShowAddGrantDialog a ->
            let s_ = m.s in
            ({m | s = {s_ | openAddGrantsDialogFor = Just a}}, Cmd.none)
        AddGrantDialogCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | openAddGrantsDialogFor = Nothing}}, Cmd.none)
        SelectOrUnselectGrantToDelete a ->
            let s_ = m.s in
            ({m | s = {s_ | selectedGrantsForDelete = Util.addOrDeleteElement s_.selectedGrantsForDelete a}}
            , Cmd.none
            )
        AddingGrantPermissionChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | addingGrantPermission = a}}
            , Cmd.none
            )
        AddingGrantScopeChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | addingGrantScope = a}}
            , Cmd.none
            )

        AddGrant r ->
            let
                s_ = m.s
                req =
                    case r of
                        Data.Security.UserRole -> Request.Security.addUserGrant
                        Data.Security.GroupRole -> Request.Security.addGroupGrant
                perm = s_.addingGrantPermission
                scope = s_.addingGrantScope
            in
                ( {m | s = { s_
                               | openAddGrantsDialogFor = Nothing
                               , addingGrantPermission = ""
                               , addingGrantScope = ""}}
                , req m perm scope
                )
        DeleteGrantBatch r ->
            let
                s_ = m.s
                req =
                    case r of
                        Data.Security.UserRole -> Request.Security.deleteUserGrant
                        Data.Security.GroupRole -> Request.Security.deleteGroupGrant
                pp = List.concat <| List.map Data.Security.grantCrumbsFromStr s_.selectedGrantsForDelete
            in
            ( {m | s = { s_
                       | selectedGrantsForDelete = []}}
            , Cmd.batch (List.map (\(p, s) -> req m p s) pp)
            )

        GroupGrantAdded _ ->
            (m, Request.Security.listGroups m)
        GroupGrantDeleted _ ->
            (m, Request.Security.listGroups m)


        ListPermissions ->
            (m, Request.Security.listPermissions m)

        GotPermissionList (Ok aa) ->
            let s_ = m.s in
            ({m | s = { s_ | permissions = aa}}, Cmd.none)
        GotPermissionList (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | permissions = [], msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to fetch factory permissions: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )


        -- Notifications
        ------------------------------
        SnackbarClosed a ->
            let
                s_ = m.s
                b = Snackbar.close a m.s.msgQueue
            in
                ({m | s = {s_ | msgQueue = b}}, Cmd.none)

        NewTime t ->
            ({m|t = t}, Cmd.none)

        -- system
        Tick a ->
            if m.s.activeTab == Msg.Cluster || m.s.rollingRestartQueue /= [] then
                ({m | t = a}, Request.Cluster.getCluster m)
            else
                (m, Cmd.none)
        NoOp ->
            (m, Cmd.none)


refreshTabMsg m t =
    case t of
        Msg.SshOps -> Cmd.batch [ Request.SshOps.listSshStoredKeys m
                                , Request.SshOps.listSshScriptTemplates m
                                ]
        Msg.Connection -> Request.Admin.getServerInfo m
        Msg.Cluster -> Request.Cluster.getCluster m
        Msg.Users -> Request.Security.listUsers m
        Msg.Groups -> Request.Security.listGroups m
        Msg.Ttaae -> Request.Ttaae.getReport m m.s.ttaaeReportShownForNode
        Msg.Vnode -> Request.Vnode.getVnodeStatus m m.s.vnodeStatusShownForNode

refreshAll m =
    Cmd.batch [ Request.SshOps.listSshStoredKeys m
              , Request.SshOps.listSshScriptTemplates m
              , Request.Admin.getServerInfo m
              , Request.Cluster.getCluster m
              , Request.Security.listUsers m
              , Request.Security.listGroups m
              , Request.Security.listPermissions m
              ]

resetCreateUserDialogFields m =
    let s_ = m.s in
    {m | s = {s_ | createUserDialogShown = False
                 , newUserName = ""
             }
    }

resetCreateGroupDialogFields m =
    let s_ = m.s in
    {m | s = {s_ | createGroupDialogShown = False
                 , newGroupName = ""
             }
    }

explainHttpError a =
    case a of
        Http.BadBody s ->
            "" ++ (Util.ellipsize s 500)
        Http.Timeout ->
            "Request timed out"
        Http.NetworkError ->
            "Network error"
        Http.BadStatus s ->
            "Bad status " ++ String.fromInt s
        Http.BadUrl s ->
            "BadUrl. This shouldn't have happened."


handleHttpError m msg err =
    let s_ = m.s in
    {m | s = {s_ | msgQueue = Snackbar.addMessage
                       (Snackbar.message (msg ++ (explainHttpError err))) m.s.msgQueue}}

handleClusterActionResult m a r =
    let s_ = m.s in
    case r of
        "ok" ->
            (m, refreshCluster)
        notOk ->
            ( {m | s = {s_ | msgQueue = Snackbar.addMessage
                              (Snackbar.message (a ++ " error: " ++ notOk)) m.s.msgQueue}}
            , Cmd.none
            )


refreshCluster =
    perform (\_ -> GetCluster) Time.now


connectedNode c =
    c.current
        |> List.filterMap (\{isMe, name} -> if isMe then Just name else Nothing)
        |> List.head
        |> Maybe.withDefault ""
