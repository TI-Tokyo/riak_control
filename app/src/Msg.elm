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

module Msg exposing
    ( Msg(..)
    , Tab(..)
    , getNewTime
    )

import Data.SshOps
import Data.Security exposing (User, Group, Grant)
import Data.Server exposing
    ( ServerInfo
    , ServerConfig
    )
import Data.Cluster exposing (Cluster, CurrentMember)
import Data.Ttaae
import Data.Vnode

import Task
import Http
import Time
import RemoteData
import Material.Snackbar as Snackbar
import File exposing (File)
import Dict exposing (Dict)


type Tab
    = SshOps
    | Connection
    | Cluster
    | Vnode
    | Ttaae
    | Users
    | Groups

type Msg
    -- SshOps
    ----------
    = RefreshBootOptions
    | RctlEditAdminCredsDialogCancelled
    | RctlEditAdminCredsDialogConfirmed
    | RctlAdminCredsNameChanged String
    | RctlAdminCredsPasswordChanged String
    | ShowRctlEditAdminCredsDialog

    | GetSshScriptTemplateList
    | GotSshScriptTemplateList (Result Http.Error (List Data.SshOps.ScriptTemplate))
    | GetSshKeyList
    | GotSshKeyList (Result Http.Error (List Data.SshOps.SshKey))
    | StoreSshKey
    | SshKeyStored (Result Http.Error ())
    | DeleteSshKey
    | SshKeyDeleted (Result Http.Error ())
    | ExecSshScript
    | SshScriptExecuting (Result Http.Error Data.SshOps.SshSession)
    | GotScriptOutput (Result Http.Error Data.SshOps.ScriptOutput)
    | ExecSshScriptDone

    | SshTargetHostsChanged String
    | SshScriptTemplateParamChanged String String
    | SshSelectedScriptTemplateNameForExecChanged String

    | ShowAddSshKeyDialog
    | SshNewKeyNameChanged String
    | SshNewKeyBodyChanged String
    | SshAddKeyDialogCancelled
    | SshAddKeyDialogConfirmed

    | ShowDeleteSshKeyDialog
    | SshKeyNameForDeletionChanged String
    | SshDeleteKeyDialogCancelled
    | SshDeleteKeyDialogConfirmed

    -- Connection
    ----------
    | Ping
    | TimedPong (Result Http.Error Int)
    | GetServerInfo
    | GotServerInfo (Result Http.Error ServerInfo)

    -- Cluster
    | GetCluster
    | GotCluster (Result Http.Error Cluster)

    | ClusterMemberSortByFieldChanged String
    | ClusterMemberSortOrderChanged

    | ShowAddNodeDialog
    | AddNodeDialogCancelled
    | NewClusterNodeChanged String

    | NodeMenuOpen String
    | NodeMenuClose
    | PlanClear
    | PlanCleared (Result Http.Error Data.Cluster.ActionResult)
    | PlanCommit
    | PlanCommitted (Result Http.Error Data.Cluster.ActionResult)
    | PlanNodeJoin
    | PlanNodeJoined (Result Http.Error Data.Cluster.ActionResult)
    | PlanNodeLeave String
    | PlanNodeLeft (Result Http.Error Data.Cluster.ActionResult)
    | PlanNodeRemove String
    | PlanNodeRemoved (Result Http.Error Data.Cluster.ActionResult)
    | PlanNodeReplace String String
    | PlanNodeReplaced (Result Http.Error Data.Cluster.ActionResult)
    | PlanNodeForceReplace String String
    | PlanNodeForceReplaced (Result Http.Error Data.Cluster.ActionResult)
    | PlanNodeDown String
    | PlanNodeDowned (Result Http.Error Data.Cluster.ActionResult)
    | PlanNodeStop String
    | PlanNodeStopped (Result Http.Error Data.Cluster.ActionResult)

    | AskPlanNodeReplace String
    | PlanNodeReplaceDialogConfirmed
    | PlanNodeReplaceDialogCancelled
    | AskPlanNodeForceReplace String
    | PlanNodeForceReplaceDialogConfirmed
    | PlanNodeForceReplaceDialogCancelled
    | PlanNodeReplaceWithChanged String

    | GetNodeAppEnv String
    | GotNodeAppEnv (Result Http.Error Data.Cluster.ConfigResult)
    | GetNodeAdvancedConfig String
    | GotNodeAdvancedConfig (Result Http.Error Data.Cluster.ConfigResult)
    | PutNodeAdvancedConfig String String
    | PuttedNodeAdvancedConfig (Result Http.Error ())

    | NodeAppEnvDialogDismissed

    | NodeAdvancedConfigChanged String
    | NodeAdvancedConfigDialogConfirmed
    | NodeAdvancedConfigDialogCancelled

    | SignalNodeRestart String
    | SignalledNodeRestart (Result Http.Error ())

    | PromptBeginRollingRestart
    | BeginRollingRestartConfirmed
    | BeginRollingRestartCancelled
    | BeginRollingRestart
    | AttemptNodeRestart
    | WaitForNode Data.Cluster.RestartingNode

    -- TictacAAE
    | GetTtaaeReport
    | GotTtaaeReport (Result Http.Error (Dict String (List Data.Ttaae.TtaaeTree)))

    | TtaaeTreeSortByFieldChanged String
    | TtaaeTreeSortOrderChanged
    | TtaaeTreeShowForNodeChanged String

    -- Vnode
    | GetVnodeStatus
    | GotVnodeStatus (Result Http.Error (List Data.Vnode.VnodeStatus))

    | VnodeStatusSortByFieldChanged String
    | VnodeStatusSortOrderChanged
    | VnodeStatusShowForNodeChanged String

    -- Users
    | ListUsers
    | GotUserList (Result Http.Error (List User))
    | CreateUser
    | UserCreated (Result Http.Error ())
    | DeleteUser String
    | DeleteUserConfirmed
    | DeleteUserNotConfirmed
    | UserDeleted (Result Http.Error ())
    | UpdateUser

    -- Groups
    | ListGroups
    | GotGroupList (Result Http.Error (List Group))
    | CreateGroup
    | GroupCreated (Result Http.Error ())
    | DeleteGroup String
    | DeleteGroupConfirmed
    | DeleteGroupNotConfirmed
    | GroupDeleted (Result Http.Error ())
    | UpdateGroup

    | ListPermissions
    | GotPermissionList (Result Http.Error (List String))

    -- UI interactions
    ------------------
    | TabClicked Tab
    | OpenTopDrawer

    | ShowConfigDialog
    | ConfigRiakNodeUrlChanged String
    | ConfigRiakAdminUserChanged String
    | ConfigRiakAdminPasswordChanged String
    | SetConfig
    | SetConfigCancelled

    -- users
    | UserFilterChanged String
    | UserFilterInItemClicked String
    | UserSortByFieldChanged String
    | UserSortOrderChanged

    | ShowCreateUserDialog
    | NewUserNameChanged String
    | NewUserPasswordChanged String
    | CreateUserCancelled
    | ShowEditUserDialog String
    | EditUserCancelled

    | ShowEditUserGroupsDialog String
    | SelectOrUnselectUserGroupToAdd String
    | SelectOrUnselectUserGroupToDelete String
    | EditUserGroupsCancelled
    | ShowAddUserGroupDialog String
    | AddUserGroupBatch
    | DeleteUserGroupBatch
    | AddUserGroupDialogCancelled
    | UserGroupAdded (Result Http.Error ())
    | UserGroupDeleted (Result Http.Error ())
    | UserGrantAdded (Result Http.Error ())
    | UserGrantDeleted (Result Http.Error ())

    -- groups
    | GroupFilterChanged String
    | GroupFilterInItemClicked String
    | GroupSortByFieldChanged String
    | GroupSortOrderChanged

    | ShowCreateGroupDialog
    | NewGroupNameChanged String
    | CreateGroupCancelled
    | ShowEditGroupDialog Group
    | EditGroupCancelled
    | GroupGrantAdded (Result Http.Error ())
    | GroupGrantDeleted (Result Http.Error ())

    -- shared
    | ShowEditGrantsDialog String
    | SelectOrUnselectGrantToDelete String
    | EditGrantsCancelled
    | ShowAddGrantDialog String
    | AddingGrantPermissionChanged String
    | AddingGrantScopeChanged String
    | AddGrant Data.Security.Role
    | DeleteGrantBatch Data.Security.Role
    | AddGrantDialogCancelled

    -- misc
    | SnackbarClosed Snackbar.MessageId

    | NewTime Time.Posix
    | Tick Time.Posix
    | NoOp


getNewTime : Cmd Msg
getNewTime =
  Task.perform NewTime Time.now
