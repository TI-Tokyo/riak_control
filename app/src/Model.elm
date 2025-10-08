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

module Model exposing
    ( Model
    , Config
    , State
    , userBy
    , groupBy
    , nodeBy
    , clusterIsStable
    )

import Data.Server exposing (..)
import Data.Cluster exposing (..)
import Data.Security exposing (..)
import Data.Ttaae
import Data.Vnode

import Msg
import View.Common exposing (SortOrder, SortByField)

import Material.Snackbar as Snackbar
import Time
import Dict


type alias Model =
    { c : Config
    , s : State
    , t : Time.Posix
    }

type alias Config =
    { riakNodeUrl : String
    , riakAdminUser : String
    , riakAdminPassword : String
    , refreshEvery : Float
    }

type alias State =
    { cluster : Cluster
    , nodeAdvancedConfigs : Dict.Dict String String
    , nodeAppEnvs : Dict.Dict String String
    , rollingRestartQueue : List Data.Cluster.RestartingNode
    , nodeBeingRestartedNow : Maybe Data.Cluster.RestartingNode
    , users : List User
    , groups : List Group
    , permissions : List String

    , msgQueue : Snackbar.Queue Msg.Msg
    , activeTab : Msg.Tab
    , topDrawerOpen : Bool

    -- general
    , serverInfo : ServerInfo
    --
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
    , openEditGroupDialogFor : Maybe Group
    , confirmDeleteGroupDialogShownFor : Maybe String

    -- Group/User shared
    , openEditGrantsDialogFor : Maybe String
    , openAddGrantsDialogFor : Maybe String
    , selectedGrantsForDelete : List String
    , addingGrantPermission : String
    , addingGrantScope : String

    -- TictacAAE
    , ttaaeReport : Dict.Dict String (List Data.Ttaae.TtaaeTree)
    , ttaaeReportShownForNode : String
    , ttaaeTreeFilterValue : String
    , ttaaeTreeFilterIn : List String
    , ttaaeTreeSortBy : SortByField
    , ttaaeTreeSortOrder : SortOrder

    -- Vnode
    , vnodeStatus : Dict.Dict String (List Data.Vnode.VnodeStatus)
    , vnodeStatusShownForNode : String
    , vnodeStatusFilterValue : String
    , vnodeStatusFilterIn : List String
    , vnodeStatusSortBy : SortByField
    , vnodeStatusSortOrder : SortOrder
    }


userBy : Model -> (User -> String) -> String -> User
userBy m by a =
    case List.filter (\x -> a == by x) m.s.users of
        [] -> Data.Security.dummyUser
        u :: _ -> u

groupBy : Model -> (Group -> String) -> String -> Group
groupBy m by a =
    case List.filter (\x -> a == by x) m.s.groups of
        [] -> Data.Security.dummyGroup
        g :: _ -> g


nodeBy : Model -> (CurrentMember -> String) -> String -> Maybe CurrentMember
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
            (n.status == Data.Cluster.Valid) &&
                (List.member "riak_kv" n.services)
        (_, _, Nothing) ->
            m.s.nodeBeingRestartedNow == Nothing
