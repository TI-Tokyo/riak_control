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

module Model exposing
    ( Model
    , Config
    , State
    , scriptTemplateBy
    , userBy
    , groupBy
    , nodeBy
    , clusterIsStable
    )

import Data.SshOps as SshOps
import Data.VersionInfo as VersionInfo
import Data.Cluster as Cluster
import Data.Security as Security
import Data.Ttaae as Ttaae
import Data.Vnode as Vnode

import Msg
import View.Common exposing (SortOrder, SortByField)

import Material.Snackbar as Snackbar
import Time
import Dict exposing (Dict)


type alias Model =
    { c : Config
    , s : State
    , t : Time.Posix
    }

type alias Config =
    { riakControlServerUrl : String
    , riakControlServerUser : String
    , riakControlServerPassword : String
    , riakNodeUrl : String
    , riakAdminUser : String
    , riakAdminPassword : String
    , refreshEvery : Float
    }

type alias State =
    { cluster : Cluster.Cluster
    , nodeAdvancedConfigs : Dict String String
    , nodeAppEnvs : Dict String String
    , rollingRestartQueue : List Cluster.RestartingNode
    , nodeBeingRestartedNow : Maybe Cluster.RestartingNode
    , users : List Security.User
    , groups : List Security.Group
    , permissions : List String

    , msgQueue : Snackbar.Queue Msg.Msg
    , activeTab : Msg.Tab
    , topDrawerOpen : Bool

    -- boot/sshops options
    , rctlAdminCredsDialogShown : Bool
    , rctlAdminCredsNewUser : String
    , rctlAdminCredsNewPassword : String

    , sshScriptTemplateSpecs : List SshOps.ScriptTemplate
    , sshTargetHostsStr : String
    , sshSelectedScriptTemplateName : String
    , sshScriptTemplateExpertParamsShown : Bool

    , sshStoredKeys : List SshOps.SshKey
    , sshAddKeyDialogShown : Bool
    , sshNewKeyName : String
    , sshNewKeyBody : String
    , sshDeleteKeyDialogShown : Bool
    , sshKeyNameToDelete : String

    , sshCurrentSessionId : String
    , sshScriptOutput : String
    , sshScriptExecutionStatus : SshOps.SshScriptExecutionStatus

    -- connection (previously also "admin", "server",
    -- all missing the elusive point).
    , versionInfo : VersionInfo.VersionInfo
    -- ended up with 'versionInfo', following "Getting Version Info"
    -- message the author sees when he starts Call of Duty Mobile.
    , configDialogShown : Bool
    , newConfigRiakNodeUrl : String
    , newConfigRiakAdminUser : String
    , newConfigRiakAdminPassword : String

    -- cluster
    , notReadyMessage : String
    , clusterMemberSortBy : SortByField
    , clusterMemberSortOrder : SortOrder
    , nodeAppEnvShownFor : Maybe String
    , nodeAdvancedConfigShownFor : Maybe String
    --
    , addNodeDialogShown : Bool
    , newNodeToJoin : String
    , nodeMenuOpenedFor : String
    , replaceDialogShownFor : String
    , forceReplaceDialogShownFor : String
    , replaceNodeWith : String
    , rollingRestartRequestShown : Bool

    -- users
    , userFilterValue : String
    , userFilterIn : List String
    , userSortBy : SortByField
    , userSortOrder : SortOrder
    --
    , createUserDialogShown : Bool
    , newUserName : String
    , newUserPassword : String
    , openEditUserDialogFor : Maybe String
    , confirmDeleteUserDialogShownFor : Maybe String

    , openEditUserGroupsDialogFor : Maybe String
    , openAddUserGroupsDialogFor : Maybe String
    , selectedUserGroupsForAdd : List String
    , selectedUserGroupsForDelete : List String

    -- groups
    , groupFilterValue : String
    , groupFilterIn : List String
    , groupSortBy : SortByField
    , groupSortOrder : SortOrder
    --
    , createGroupDialogShown : Bool
    , newGroupName : String
    , openEditGroupDialogFor : Maybe Security.Group
    , confirmDeleteGroupDialogShownFor : Maybe String

    -- Group/User shared
    , openEditGrantsDialogFor : Maybe String
    , openAddGrantsDialogFor : Maybe String
    , selectedGrantsForDelete : List String
    , addingGrantPermission : String
    , addingGrantScope : String

    -- TictacAAE
    , ttaaeStatus : Dict String (List Ttaae.TtaaeTree)
    , ttaaeStatusShownForNode : String
    , ttaaeTreeFilterValue : String
    , ttaaeTreeFilterIn : List String
    , ttaaeTreeSortBy : SortByField
    , ttaaeTreeSortOrder : SortOrder

    -- Vnode
    , vnodeStatus : List Vnode.VnodeStatus
    , vnodeStatusShownForNode : String
    , vnodeStatusFilterValue : String
    , vnodeStatusFilterIn : List String
    , vnodeStatusSortBy : SortByField
    , vnodeStatusSortOrder : SortOrder
    , vnodeStatusExtended : Bool
    }


scriptTemplateBy : Model -> (SshOps.ScriptTemplate -> String) -> String -> SshOps.ScriptTemplate
scriptTemplateBy m by a =
    case List.filter (\x -> a == by x) m.s.sshScriptTemplateSpecs of
        [] -> SshOps.dummyScriptTemplate
        u :: _ -> u


userBy : Model -> (Security.User -> String) -> String -> Security.User
userBy m by a =
    case List.filter (\x -> a == by x) m.s.users of
        [] -> Security.dummyUser
        u :: _ -> u

groupBy : Model -> (Security.Group -> String) -> String -> Security.Group
groupBy m by a =
    case List.filter (\x -> a == by x) m.s.groups of
        [] -> Security.dummyGroup
        g :: _ -> g


nodeBy : Model -> (Cluster.CurrentMember -> String) -> String -> Maybe Cluster.CurrentMember
nodeBy m by a =
    case List.filter (\x -> a == by x) m.s.cluster.current of
        [] -> Nothing
        g :: _ -> Just g


clusterIsStable : Model -> Bool
clusterIsStable m =
    case ( m.s.cluster.current == []
         , m.s.cluster.transfers == []
         , Maybe.withDefault {name = "", lastUptime = -1} m.s.nodeBeingRestartedNow |> .name |> nodeBy m .name
         ) of
        (True, _, _) ->   -- no cluster view (e.g., claimant down)
            False
        (_, False, _) ->  -- transfers ongoing
            False
        (_, _, Just n) ->
            (n.status == Cluster.Valid) &&
                (List.member "riak_kv" n.services)
        (_, _, Nothing) ->
            m.s.nodeBeingRestartedNow == Nothing
