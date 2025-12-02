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

module Request.SshOps exposing
    ( listSshStoredKeys
    , listSshScriptTemplates
    , storeSshKey
    , deleteSshKey
    , execSshScript
    )

import Model exposing (Model)
import Data.SshOps exposing (..)
import Data.Json
import Msg exposing (Msg(..))
import Util
import Request.Util exposing (..)

import Http
import HttpBuilder
import HttpBuilder.Task
import Url.Builder
import Json.Encode
import Base64


listSshStoredKeys : Model -> Cmd Msg
listSshStoredKeys m =
    Url.Builder.crossOrigin m.c.riakControlServerUrl [] []
        |> HttpBuilder.post
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withJsonBody listSshKeysEncoder
        |> HttpBuilder.withExpect (Http.expectJson GotSshKeyList Data.Json.decodeSshStoredKeyList)
        |> HttpBuilder.request

listSshKeysEncoder =
    Json.Encode.object
        [ ("command", Json.Encode.string "list_ssh_keys") ]


listSshScriptTemplates : Model -> Cmd Msg
listSshScriptTemplates m =
    Url.Builder.crossOrigin m.c.riakControlServerUrl [] []
        |> HttpBuilder.post
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withJsonBody listSshScriptTemplatesEncoder
        |> HttpBuilder.withExpect (Http.expectJson GotSshScriptTemplateList Data.Json.decodeSshScriptTemplateList)
        |> HttpBuilder.request

listSshScriptTemplatesEncoder =
    Json.Encode.object
        [ ("command", Json.Encode.string "list_script_templates") ]


storeSshKey : Model -> StoreKeyCmdParams -> Cmd Msg
storeSshKey m pp =
    Url.Builder.crossOrigin m.c.riakControlServerUrl [] []
        |> HttpBuilder.post
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withJsonBody (storeSshKeyCommandEncoder pp)
        |> HttpBuilder.withExpect (Http.expectWhatever SshKeyStored)
        |> HttpBuilder.request

storeSshKeyCommandEncoder {name, body} =
    Json.Encode.object
        [ ("command", Json.Encode.string "store_ssh_key")
        , ("name", Json.Encode.string name)
        , ("body", Json.Encode.string body)
        ]

deleteSshKey : Model -> DeleteKeyCmdParams -> Cmd Msg
deleteSshKey m pp =
    Url.Builder.crossOrigin m.c.riakControlServerUrl [] []
        |> HttpBuilder.post
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withJsonBody (deleteSshKeyCommandEncoder pp)
        |> HttpBuilder.withExpect (Http.expectWhatever SshKeyStored)
        |> HttpBuilder.request

deleteSshKeyCommandEncoder {name} =
    Json.Encode.object
        [ ("command", Json.Encode.string "delete_ssh_key")
        , ("name", Json.Encode.string name)
        ]

execSshScript : Model -> ExecScriptCmdParams -> Cmd Msg
execSshScript m pp =
    Url.Builder.crossOrigin m.c.riakControlServerUrl [] []
        |> HttpBuilder.post
        |> HttpBuilder.withHeaders (stdHeaders m)
        |> HttpBuilder.withJsonBody (sshCommandEncoder pp)
        |> HttpBuilder.withExpect (Http.expectWhatever SshScriptExecuted)
        |> HttpBuilder.request

sshCommandEncoder {hosts, user, sshKeyName, scriptName, params} =
    let
        pp = List.map (\{name, value} -> (name, Json.Encode.string value)) params
    in
        Json.Encode.object
            [ ("command", Json.Encode.string "ssh_exec_script")
            , ("hosts", (Json.Encode.list Json.Encode.string hosts))
            , ("script_name", Json.Encode.string scriptName)
            , ("user", Json.Encode.string user)
            , ("ssh_key_name", Json.Encode.string sshKeyName)
            , ("params", Json.Encode.object pp)
            ]


stdHeaders m =
    let ct = "application/json" in
    [ ("accept", ct)
    , ("content-type", ct)
    , ("authorization",
        "Basic " ++ (Base64.encode (m.c.riakAdminUser ++ ":" ++ m.c.riakAdminPassword)))
    ]
