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

module Data.SshOps exposing (..)

import Regex

type Command
    = GetScriptTemplateList
    | ExecScriptCommand ExecScriptCmdParams
    | StoreKeyCommand StoreKeyCmdParams
    | DeleteKeyCommand DeleteKeyCmdParams

type alias ScriptTemplate =
    { name : String
    , body : String
    , params : List TemplateParameter
    }

type alias TemplateParameter =
    { name : String
    , value : String
    , description : String
    }

type alias ExecScriptCmdParams =
    { hosts : List HostWithCreds
    , scriptTemplateName : String
    , scriptTemplateParams : List TemplateParameter
    }

type alias HostWithCreds =
    { url : String
    , user : String
    , sshKeyName : String
    }

type alias StoreKeyCmdParams =
    { name : String
    , body : String
    }

type alias DeleteKeyCmdParams =
    { name : String
    }

type alias SshKey =
    { name : String
    , created : String
    , body : String
    }


dummySshKey =
    { name = ""
    , body = ""
    , created = ""
    }

dummyScriptTemplate =
    { name = ""
    , body = ""
    , params = []
    }


targetHostsFromStr s =
    let
        ip = "^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
        fqdn = "(?=^.{4,253}$)(^((?!-)[a-zA-Z0-9-]{0,62}[a-zA-Z0-9]\\.)+[a-zA-Z]{2,63}$)"
        host = "("++ip++"|"++fqdn++")"
        user = "([a-zA-Z0-9]+)"
        sshKey = "(\\([a-zA-Z0-9]+)\\)"
        reStr = user++"@"++host++" +"++sshKey
        re = Maybe.withDefault Regex.never <| Regex.fromString reStr
        comma = Maybe.withDefault Regex.never <| Regex.fromString " *, *"
        convert =
            \ss ->
                case Regex.find re ss of
                    [m1, m2, m3] ->
                        Just { user = m1.match
                             , url = m2.match
                             , sshKeyName = m3.match
                             }
                    _ ->
                        Nothing
    in
        Regex.split comma s |> List.filterMap convert

targetHostsToStr hh =
    List.map (\{url, user, sshKeyName} ->
                  user++"@"++url++" ("++sshKeyName++")"
             ) hh |> String.join ", "
