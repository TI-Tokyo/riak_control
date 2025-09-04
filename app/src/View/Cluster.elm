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

module View.Cluster exposing
    ( makeContent
    )

import Model exposing (Model)
import Msg exposing (Msg(..))
import Data.Cluster
import View.Cluster.Dialog
import View.Common exposing (SortByField(..))
import View.Shared
import View.Style
import Util

import Html exposing (Html, text, div, img, pre)
import Html.Attributes exposing (attribute, style, src)
import Material.Card as Card
import Material.Button as Button
import Material.IconButton as IconButton
import Material.List as List
import Material.List.Item as ListItem
import Material.Menu as Menu
import Material.Fab as Fab
import Material.Typography as Typography
import Iso8601
import Dict
import Numeral


makeContent m =
    if m.s.notReadyMessage /= "" then
        div [ style "align-content" "center" ] [text m.s.notReadyMessage ]
    else
        makeProperContent m

makeProperContent m =
    div View.Style.topContent
        [ makeRollingRestartProgress m
        , makeTransfers m
        , makeAddNodeFab m
        , makeCluster m
        , View.Cluster.Dialog.maybeMakeAddNodeDialog m
        , View.Cluster.Dialog.maybeMakeReplacementDialog m
        , View.Cluster.Dialog.maybeMakeNodeAppEnvDialog m
        , View.Cluster.Dialog.maybeMakeNodeAdvancedConfigDialog m
        , View.Cluster.Dialog.maybePromptRollingRestartDialog m
        ]

makeCluster m =
    let haveStaged = (m.s.cluster.stagedChanges /= []) in
    div [ style "display" "grid"
        , style "grid-template-columns" (if haveStaged then "2fr 1fr" else "1fr")
        , style "padding" "1em"
        ] [ makeCurrentCluster m
          , div [ style "display" "grid"
                , style "grid-template-columns" "1fr"
                ] [ makeStagedChanges m
                  , makeFinalCluster m
            ]
    ]

makeAddNodeFab m =
    if m.s.addNodeDialogShown || m.s.rollingRestartQueue /= [] then
        div [] []
    else
        div []
            [ Fab.fab
                  (Fab.config
                  |> Fab.setOnClick ShowAddNodeDialog
                  |> Fab.setAttributes View.Style.createFab
                  )
                  (Fab.icon "add")
            ]


-- current cluster

makeCurrentCluster m =
    let
        haveStaged = (m.s.cluster.stagedChanges /= [])
        members =
            case m.s.cluster.current |> (sortCurrent m) |> List.map (makeCurrentMember m) of
                [] ->
                    div [] [ text "(cluster is empty)" ]
                rr ->
                    div View.Style.card rr
        rrButtonDisabled =
            not (Model.clusterIsStable m)
        maybeRRButton =
            if m.s.rollingRestartQueue == [] && m.s.cluster.stagedChanges == [] then
                [ Button.text (Button.config
                              |> Button.setDisabled rrButtonDisabled
                              |> Button.setOnClick PromptBeginRollingRestart)
                      "Rolling Restart" ]
            else
                []
    in
        div ([ style "padding" "1em"
             ] ++ (if haveStaged then [style "border-right" "solid grey"] else []))
            ([ section "Current Cluster"
             , members
             ] ++ maybeRRButton)

makeCurrentMember m u =
    let
        li = \txt msg ->
             (ListItem.listItem (ListItem.config |> ListItem.setOnClick msg)
                  [ text txt ]
             )
        menu =
            if m.s.rollingRestartQueue == [] then
                div [ Menu.surfaceAnchor ]
                    [ Button.text (Button.config |> Button.setOnClick (NodeMenuOpen u.name)) "..."
                        , Menu.menu
                              (Menu.config
                              |> Menu.setOpen (m.s.nodeMenuOpenedFor == u.name)
                              |> Menu.setOnClose NodeMenuClose)
                              (li "Leave" (PlanNodeLeave u.name))
                              [ li "Remove" (PlanNodeRemove u.name)
                              , li "Replace" (AskPlanNodeReplace u.name)
                              , li "Force Replace" (AskPlanNodeForceReplace u.name)
                              , li "Down" (PlanNodeDown u.name)
                              , li "Stop" (PlanNodeStop u.name)
                              , li "App env" (GetNodeAppEnv u.name)
                              , li "advanced.config" (GetNodeAdvancedConfig u.name)
                              , li "Restart" (SignalNodeRestart u.name)
                              ]
                        ]
            else
                div [] []
        paint =
            case u.status of
                Data.Cluster.Valid -> []
                Data.Cluster.Down -> [ style "color" "gray" ]
                Data.Cluster.Leaving -> [ style "background" "cyan" ]
                Data.Cluster.Joining -> [ style "background" "green" ]
                _ -> []
    in
        Card.card Card.config
            { blocks =
                  ( Card.block <|
                        div View.Style.cardInnerHeader
                        [ text u.name ]
                  , [ Card.block <|
                          div (View.Style.cardInnerContent ++ paint)
                          [ currentCardContent m u |> text
                          , menu
                          ]
                    ]
                  )
            , actions = currentMemberCardActions m u
            }

currentCardContent m u =
    let
        mf1 = (\a -> Numeral.format "000,00 b" (toFloat a))
        mf2 = (\a -> Numeral.format "0.00" a)
    in
    if u.status == Data.Cluster.Down then
        " Status: down"
    else
        "                Status: " ++ (Data.Cluster.currentMemberStatusToStr u.status) ++ "\n" ++
        "        Ring/Pending %: " ++ (mf2 (u.ringPct * 100)) ++ " / " ++ (mf2 (u.pendingPct * 100)) ++ "\n" ++
        " Mem total/erlang/used: " ++ (mf1 u.memTotal) ++ " / " ++ (mf1 u.memErlang) ++ " / " ++ (mf1 u.memUsed) ++ "\n" ++
        "                Uptime: " ++ u.systemInfo.uptimeStr ++ "\n" ++
        "          Riak version: " ++ u.systemInfo.riakVersion

currentMemberCardActions m u =
    Just <|
        Card.actions
            { buttons = []
            , icons = (maybeClaimant u) ++ (maybeConnectedTo u)
            }

maybeClaimant u =
    if u.claimant then
        [ Card.icon (IconButton.config |> IconButton.setDisabled True) (IconButton.icon "copyright") ]
    else
        []

maybeConnectedTo u =
    if u.isMe then
        [ Card.icon (IconButton.config |> IconButton.setDisabled True) (IconButton.icon "api") ]
    else
        []


-- staged changes

makeStagedChanges m =
    let
        (first, rest) =
            case m.s.cluster.stagedChanges of
                (a :: b) -> (a, b)
                _ -> ({name = "", action = Data.Cluster.BAD_STAGE_ACTION}, [])
        f = (\{name, action} ->
                 ListItem.listItem (ListItem.config |> ListItem.setDisabled True)
                   [ pre [] [ text ((Data.Cluster.stageActionToStr action) ++ " " ++ name) ] ]
            )
        content =
            List.list (List.config |> List.setDense True)
                (f first)
                (List.map f rest)
    in
        if m.s.cluster.stagedChanges == [] then
            div [] []
        else
            div [ style "padding" "1em"
                , style "border-bottom" "solid grey"
                ] [ section "Staged Changes"
                  , content
                  ]



-- final cluster

makeFinalCluster m =
    let
        content =
            case m.s.cluster.planned |> (sortPlanned m) |> List.map (makeFinalMember m) of
                [] ->
                    div [ style "font-size" "small" ] [ text "(no staged changes)" ]
                rr ->
                    div [] [ div View.Style.card rr
                           , div [] [ Button.text (Button.config |> Button.setOnClick PlanClear) "Clear"
                                    , Button.text (Button.config |> Button.setOnClick PlanCommit) "Commit"
                                    ]
                           ]
    in
        if m.s.cluster.stagedChanges == [] then
            div [] []
        else
            div [ style "padding" "1em"
                ] [ section "Final Cluster"
                  , content
                  ]


makeFinalMember m u =
    Card.card Card.config
        { blocks =
              ( Card.block <|
                    div View.Style.cardInnerHeader
                    [ text u.name ]
              , [ Card.block <|
                      div View.Style.cardInnerContent
                      [ finalMemberCardContent m u |> text
                      ]
                ]
              )
        , actions = Nothing
        }

finalMemberCardContent m u =
    let mf = (\a -> Numeral.format "000,0" a) in
    " Ring/Pending %: " ++ (mf u.ringPct) ++ " / " ++ (mf u.pendingPct)


sortCurrent m aa =
    let
        aa0 =
            case m.s.clusterMemberSortBy of
                Name -> List.sortBy .name aa
                MemTotal -> List.sortBy .memTotal aa
                MemErlang -> List.sortBy .memErlang aa
                MemUsed -> List.sortBy .memUsed aa
--                Uptime -> List.sortBy (.systemInfo >> .uptime) aa
                _ -> aa
    in
        if m.s.clusterMemberSortOrder then aa0 else List.reverse aa0

sortPlanned m aa =
    let
        aa0 =
            case m.s.clusterMemberSortBy of
                Name -> List.sortBy .name aa
                _ -> aa
    in
        if m.s.clusterMemberSortOrder then aa0 else List.reverse aa0

boolToStr a =
    case a of
        True -> "yes"
        False -> "no"

section a =
    div [ style "font-size" "x-large"
        , style "padding-bottom" "1em"
        , style "font-variant-caps" "small-caps"
        ] [ text a ]


makeRollingRestartProgress m =
    if m.s.rollingRestartQueue == [] then
        div [] []
    else
        let
            endMsg =
                case m.s.rollingRestartQueue of
                    [] -> ""
                    n :: _ -> ", next is " ++ n.name
            -- _ = Debug.log "m.s.rollingRestartQueue" m.s.rollingRestartQueue
        in
            div [ style "color" "red"
                ] [ text <| "Rolling restart in progress: restarting now "
                        ++ (Maybe.withDefault {name = "", lastUptime = -1} m.s.nodeBeingRestartedNow |> .name)
                        ++ endMsg ]

makeTransfers m =
    if m.s.cluster.transfers == [] then
        div [ style "color" "green"
            ] [ text <| "No active transfers" ]
    else
        div [ style "color" "blue"
            ] [ text <| (waitingHandoffsStr m.s.cluster.transfers) ++ "\n" ++
                    (stoppedTransfersStr m.s.cluster.transfers) ]

waitingHandoffsStr tt =
    let
        totals =
            List.foldl
                (\{state, count} {n, p} ->
                     if state == Data.Cluster.WaitingToHandoff then
                         {n = n+1, p = p + count}
                     else
                         {n = n, p = p}
                ) {n = 0, p = 0} tt
    in
        if totals.n > 0 then
            (String.fromInt totals.n) ++ " node(s) waiting to hand off " ++ (String.fromInt totals.p) ++ " partition(s)"
        else
            "all handoffs completed"

stoppedTransfersStr tt =
    let
        totals =
            List.foldl
                (\{state, count} {n, p} ->
                     if state == Data.Cluster.Stopped then
                         {n = n+1, p = p + count}
                     else
                         {n = n, p = p}
                ) {n = 0, p = 0} tt
    in
        if totals.n > 0 then
            (String.fromInt totals.n) ++ " node(s) do not have a total of "  ++ (String.fromInt totals.p) ++ " primary partitions running"
        else
            ""


makeDownNodes m =
    if m.s.cluster.downNodes == [] then
        div [] []
    else
        div [ style "color" "red"
            ] [ text <| (List.length m.s.cluster.downNodes |> String.fromInt) ++ " node(s) are currently down" ]
