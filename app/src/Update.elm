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
import Data.VersionInfo
import Data.Cluster exposing (emptyCluster)
import Data.Security exposing (dummyUser, dummyGroup)
import Data.Ttaae
import Data.Vnode
import Data.Json
import View.Common
import Util
import Static

import Time
import Task exposing (attempt, perform, andThen, succeed, sequence)
import Platform.Cmd
import Dict exposing (Dict)
import Json.Decode
import Http
import Process
import RemoteData
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

        -- Rctl Admin Creds
        ------------------------------
        ShowRctlEditAdminCredsDialog ->
            let s_ = m.s in
            ({m | s = {s_ | rctlAdminCredsDialogShown = True}}, Cmd.none)
        RctlAdminCredsNameChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | rctlAdminCredsNewUser = a}}, Cmd.none)
        RctlAdminCredsPasswordChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | rctlAdminCredsNewPassword = a}}, Cmd.none)
        RctlEditAdminCredsDialogCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | rctlAdminCredsDialogShown = False}}, Cmd.none)
        RctlEditAdminCredsDialogConfirmed ->
            let
                c_ = m.c
                s_ = m.s
            in
                ( {m | s = {s_ | rctlAdminCredsDialogShown = False}
                    , c = {c_ | riakControlServerUser = s_.rctlAdminCredsNewUser
                              , riakControlServerPassword = s_.rctlAdminCredsNewPassword}}
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
            , Request.SshOps.listSshStoredKeys m
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
            , Request.SshOps.listSshStoredKeys m
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
                pp = { name = m.s.sshKeyNameToDelete }
            in
                ({m | s = {s_ | sshDeleteKeyDialogShown = False}}, Request.SshOps.deleteSshKey m pp)

        SshScriptTemplateExpertToggle ->
            let s_ = m.s in
            ( {m | s = {s_ | sshScriptTemplateExpertParamsShown = not s_.sshScriptTemplateExpertParamsShown}}
            , Cmd.none
            )

        SshSelectedScriptTemplateNameForExecChanged a ->
            let s_ = m.s in
            ( {m | s = {s_ | sshSelectedScriptTemplateName = a}}
            , Cmd.none
            )

        SshTargetHostsChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | sshTargetHostsStr = a}}, Cmd.none)

        SshScriptTemplateParamChanged a s ->
            let
                s_ = m.s
                pp0 = Model.scriptTemplateBy m .name m.s.sshSelectedScriptTemplateName |> .params
                f1 = \{name, value, description, expert} ->
                    if name == a then
                        {name = name, value = s, description = description, expert = expert}
                    else
                        {name = name, value = value, description = description, expert = expert}
                pp = List.map f1 pp0
                f2 = \t ->
                     if t.name == m.s.sshSelectedScriptTemplateName then
                         {t | params = pp}
                     else
                         t
                tt = List.map f2 m.s.sshScriptTemplateSpecs
            in
                ({m | s = {s_ | sshScriptTemplateSpecs = tt}}, Cmd.none)

        ExecSshScript ->
            let
                tpp = Model.scriptTemplateBy m .name m.s.sshSelectedScriptTemplateName |> .params
                rpp = { hosts = m.s.sshTargetHostsStr
                      , scriptTemplateName = m.s.sshSelectedScriptTemplateName
                      , scriptTemplateParams = tpp
                      }
            in
                (m, Request.SshOps.execSshScript m rpp)
        SshScriptExecuting (Ok {sessionId}) ->
            let s_ = m.s in
            ( {m | s = {s_ | sshCurrentSessionId = sessionId
                           , sshScriptExecutionStatus = Data.SshOps.ScriptRunning}}
            , Request.SshOps.getScriptOutput m {sessionId = sessionId}
            )
        SshScriptExecuting (Err err) ->
            let s_ = m.s in
            ( {m | s = {s_ | sshScriptExecutionStatus = Data.SshOps.ScriptFinished
                           , msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to execute script: " ++ (explainHttpError err))) m.s.msgQueue}}
            , Cmd.none
            )

        GotScriptOutput (Ok {sessionId, finished, output})  ->
            let
                s_ = m.s
                newOutput =
                    if s_.sshScriptOutput == Static.awaitingOutput then
                        output
                    else
                        s_.sshScriptOutput ++ output
                (newExecStatus, cmd) =
                    if finished then
                        ( Data.SshOps.ScriptFinished
                        , Cmd.none
                        )
                    else
                        ( Data.SshOps.ScriptRunning
                        , Request.SshOps.getScriptOutput m {sessionId = sessionId}
                        )
            in
                ( {m | s = {s_ | sshScriptExecutionStatus = newExecStatus
                               , sshScriptOutput = newOutput}}
                , cmd
                )
        GotScriptOutput (Err err)  ->
            let s_ = m.s in
            ( {m | s = {s_ | sshScriptExecutionStatus = Data.SshOps.ScriptFinished
                           , msgQueue = Snackbar.addMessage
                            (Snackbar.message ("Failed to get script output: " ++ (explainHttpError err))) s_.msgQueue}}
            , Cmd.none
            )

        ExecSshScriptInterrupt ->
            let s_ = m.s in
            (m, Request.SshOps.interruptSshScript m {sessionId = m.s.sshCurrentSessionId})

        SshScriptInterrupted (Ok ()) ->
            let s_ = m.s in
            ( {m | s = {s_ | sshScriptExecutionStatus = Data.SshOps.ScriptFinished
                           , msgQueue = Snackbar.addMessage
                            (Snackbar.message "Script interrupted") s_.msgQueue}}
            , Cmd.none
            )
        SshScriptInterrupted (Err err) ->
            ( handleHttpError m "Failed to interrupt script: " err
            , Cmd.none
            )

        ExecSshScriptDone ->
            let s_ = m.s in
            ( {m | s = {s_ | sshScriptExecutionStatus = Data.SshOps.ScriptNotStarted
                           , sshScriptOutput = Static.awaitingOutput}}
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

        GetVersionInfo ->
            (m, Request.Admin.getVersionInfo m)
        GotVersionInfo (Ok a) ->
            let
                s_ = m.s
            in
                ({m | s = {s_ | versionInfo = a}}, Cmd.none)
        GotVersionInfo (Err err) ->
            ( handleHttpError m "Failed to get server version info: " err
            , Cmd.none
            )


        -- Admin creds
        ------------------------------
        ShowConfigDialog ->
            let s_ = m.s in
            ({m | s = {s_ | configDialogShown = True}}, Cmd.none)
        ConfigRiakNodePingUrlChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigRiakNodePingUrl = s}}, Cmd.none)
        ConfigRiakAdminCtlUrlChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigRiakAdminCtlUrl = s}}, Cmd.none)
        ConfigRiakAdminCtlUserChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigRiakAdminCtlUser = s}}, Cmd.none)
        ConfigRiakAdminCtlPasswordChanged s ->
            let s_ = m.s in
            ({m | s = {s_ | newConfigRiakAdminCtlPassword = s}}, Cmd.none)
        SetConfig ->
            let
                c_ = m.c
                s_ = m.s
            in
                ( { m | c = {c_ | riakNodePingUrl = m.s.newConfigRiakNodePingUrl
                                , riakAdminCtlUrl = m.s.newConfigRiakAdminCtlUrl
                                , riakAdminCtlUser = m.s.newConfigRiakAdminCtlUser
                                , riakAdminCtlPassword = m.s.newConfigRiakAdminCtlPassword
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
            (m, Request.Cluster.getClusterStatus m)
        GotCluster (Ok a) ->
            let
                s_ = m.s
                prevT = s_.ttaaeStatusShownForNode
                prevV = s_.vnodeStatusShownForNode
                thisNode = connectedNode a
            in
                ( {m | s = {s_ | cluster = a
                               , notReadyMessage = ""
                               , ttaaeStatusShownForNode = if prevT == "" then thisNode else prevT
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
                   |> List.map (\{name, versionInfo} -> { name = name
                                                        , lastUptime = versionInfo.uptime
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
                            cm.versionInfo.uptime
            in
                if currentUptime /= -1 && currentUptime < n.lastUptime then
                    (m, perform (\_ -> AttemptNodeRestart) Time.now)
                else
                    (m, perform (\_ -> WaitForNode n) (Process.sleep 5000 |> andThen (\_ -> Time.now)))


        -- TictacAAE
        ------------------------------
        GetTtaaeStatus ->
            (m, Request.Ttaae.getStatus m m.s.ttaaeStatusShownForNode)
        GotTtaaeStatus (Ok r) ->
            let s_ = m.s in
            ( {m | s = {s_ | ttaaeStatus = Dict.insert m.s.ttaaeStatusShownForNode r s_.ttaaeStatus}}
            , Cmd.none
            )
        GotTtaaeStatus (Err err) ->
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
            ({m | s = {s_ | ttaaeStatusShownForNode = a}}, Request.Ttaae.getStatus m a)


        -- Vnode
        ------------------------------
        GetVnodeStatus ->
            (m, Request.Vnode.getVnodeStatus m m.s.vnodeStatusShownForNode)
        GotVnodeStatus (Ok r) ->
            let s_ = m.s in
            ( {m | s = {s_ | vnodeStatus = r}}
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

        VnodeStatusExtendedToggle ->
            let s_ = m.s in
            ({m | s = {s_ | vnodeStatusExtended = not s_.vnodeStatusExtended}}, Cmd.none)


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
        NewUserExpiresInChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | newUserExpiresIn = a}}, Cmd.none)
        CalculateNewUserExpiryAndCreateUser ->
            (m, perform (\t -> CreateUser t) Time.now)
        CreateUser t ->
            (m, Request.Security.createUser m t)
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

        AddUserPermission ->
            let s_ = m.s in
            ( { m | s = { s_ | openAddPermissionsDialogFor = Nothing
                             , addingPermissionPermission = ""}}
              , Request.Security.addUserPermissions m [m.s.addingPermissionPermission]
            )
        DeleteUserPermissions ->
            let s_ = m.s in
            ( {m | s = { s_ | selectedPermissionsForDelete = []}}
            , Request.Security.deleteUserPermissions m m.s.selectedPermissionsForDelete
            )

        UserPermissionsAdded _ ->
            (m, Request.Security.listUsers m)
        UserPermissionsDeleted _ ->
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

        AddGroupPermission ->
            let s_ = m.s in
            ( { m | s = { s_ | openAddPermissionsDialogFor = Nothing
                             , addingPermissionPermission = ""}}
              , Request.Security.addGroupPermissions m [m.s.addingPermissionPermission]
            )
        DeleteGroupPermissions ->
            let s_ = m.s in
            ( {m | s = { s_ | selectedPermissionsForDelete = []}}
            , Request.Security.deleteGroupPermissions m m.s.selectedPermissionsForDelete
            )

        GroupPermissionsAdded _ ->
            (m, Request.Security.listGroups m)
        GroupPermissionsDeleted _ ->
            (m, Request.Security.listGroups m)


        -- Group/User shared
        ShowEditPermissionsDialog a ->
            let s_ = m.s in
            ({m | s = {s_ | openEditPermissionsDialogFor = Just a}}, Cmd.none)
        EditPermissionsCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | openEditPermissionsDialogFor = Nothing}}, Cmd.none)


        ShowAddPermissionDialog a ->
            let s_ = m.s in
            ({m | s = {s_ | openAddPermissionsDialogFor = Just a}}, Cmd.none)
        AddPermissionDialogCancelled ->
            let s_ = m.s in
            ({m | s = {s_ | openAddPermissionsDialogFor = Nothing}}, Cmd.none)
        SelectOrUnselectPermissionToDelete a ->
            let s_ = m.s in
            ({m | s = {s_ | selectedPermissionsForDelete = Util.addOrDeleteElement s_.selectedPermissionsForDelete a}}
            , Cmd.none
            )
        AddingPermissionPermissionChanged a ->
            let s_ = m.s in
            ({m | s = {s_ | addingPermissionPermission = a}}
            , Cmd.none
            )


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
                ({m | t = a}, Request.Cluster.getClusterStatus m)
            else
                (m, Cmd.none)
        NoOp ->
            (m, Cmd.none)


refreshTabMsg m t =
    case t of
        Msg.SshOps -> Cmd.batch [ Request.SshOps.listSshStoredKeys m
                                , Request.SshOps.listSshScriptTemplates m
                                ]
        Msg.Connection -> Request.Admin.getVersionInfo m
        Msg.Cluster -> Request.Cluster.getClusterStatus m
        Msg.Users -> Request.Security.listUsers m
        Msg.Groups -> Request.Security.listGroups m
        Msg.Ttaae -> Request.Ttaae.getStatus m m.s.ttaaeStatusShownForNode
        Msg.Vnode -> Request.Vnode.getVnodeStatus m m.s.vnodeStatusShownForNode

refreshAll m =
    Cmd.batch [ Request.SshOps.listSshStoredKeys m
              , Request.SshOps.listSshScriptTemplates m
              , Request.Admin.getVersionInfo m
              , Request.Cluster.getClusterStatus m
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
