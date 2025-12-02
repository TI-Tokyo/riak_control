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
