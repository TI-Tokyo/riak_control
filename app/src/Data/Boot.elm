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

module Data.Boot exposing (..)

type Command
    = GetScriptTemplateList
    | SshCommand SshCmdParams
    | StoreKeyCommand StoreKeyCmdParams
    | DeleteKeyCommand DeleteKeyCmdParams

type alias ScriptTemplate =
    { name : String
    , body : String
    , params : List (String, String)
    }

type alias SshCmdParams =
    { hosts : List HostWithCreds
    , scriptId : String  -- a template, from a lib stored on the server
    , params : List (String, String)
    }

type alias HostWithCreds =
    { host : String
    , user : String
    , keyId : String
    }

type alias StoreKeyCmdParams =
    { id : String
    , body : String
    }

type alias DeleteKeyCmdParams =
    { id : String
    }

type alias SshKey =
    { id : String
    , created : String
    , body : String
    }
