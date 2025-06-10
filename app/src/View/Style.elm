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

module View.Style exposing (..)

import Html.Attributes exposing (style)
import Material.Typography as Typography

topContent =
    [ style "display" "grid"
    , style "grid-template-columns" "1"
    ]

subTab =
    [ style "align-self" "end"
    , style "align-content" "end"
    , style "padding" "0.1em 0"
    , style "scale" "0.7"
    , style "z-index" "20"
    ]

card =
    [ style "display" "flex"
    , style "flex-wrap" "wrap"
    , style "gap" "1em"
    ]

cardInnerHeader =
    [ style "padding" ".5em .5em 0"
    , style "border-bottom" "solid #cccccc"
    , Typography.headline5
    ]

cardInnerContent =
    [ style "white-space" "pre"
    , style "font-family" "monospace"
    , style "padding" "1.5em"
    ]

cardInnerBlock =
    [ style "padding" ".5em"
    , style "white-space" "pre"
    , style "font-family" "monospace"
    ]

jsonInset =
    [ style "scale" "0.8"
    , style "background-color" "#f5f5f5"
    , style "border" "thick"
    , style "border-radius" "0 0 1em 0"
    , style "font-family" "monospace"
    , style "white-space" "pre"
    ]

createFab =
    [ style "position" "fixed"
    , style "bottom" "2rem"
    , style "right" "2rem"
    ]

createFab2 =
    [ style "position" "fixed"
    , style "bottom" "2rem"
    , style "right" "7rem"
    ]

filterAndSort =
    [ style "display" "flex"
    , style "flex-wrap" "nowrap"
    , style "scale" "0.6"
    , style "opacity" "0.95"
    , style "padding" "0.5em 1.5em"
    , style "height" "5em"
    , style "background" "white"
    , style "z-index" "21"
    , style "align-items" "center"
    , style "justify-content" "center"
    ]

center =
    [ style "display" "grid"
    , style "align-items" "center"
    , style "justify-content" "center"
    ]
