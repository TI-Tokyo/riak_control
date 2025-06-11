// ---------------------------------------------------------------------
//
// Copyright (c) 2025 TI Tokyo    All Rights Reserved.
//
// This file is provided to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file
// except in compliance with the License.  You may obtain
// a copy of the License at

//   http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.
//
// ---------------------------------------------------------------------

var path = require('path');
const CopyWebpackPlugin = require("copy-webpack-plugin");
const webpack = { EnvironmentPlugin } = require("webpack");

const destDir = path.resolve(__dirname, "../build");

module.exports = {
    entry: {
        application: [
            "babel-polyfill",
            path.join(__dirname, "../src/index.js")
        ],
        vendor: [
            "bootstrap",
            "@webcomponents/webcomponentsjs/webcomponents-loader",
            "@webcomponents/webcomponentsjs/custom-elements-es5-adapter",
            "web-component"
        ]
    },
    output: {
        filename: "rc_ui-[name].js",
        path: destDir,
    },
    module: {
        rules: [
            {
                test: /\.html$/i,
                loader: "file-loader",
            },
            {
                test: /\.(sass|less|css)$/,
                use: ['style-loader', 'css-loader', 'less-loader']
            },
            {
                test: /\.js$/,
                exclude: [ /elm-stuff/, /node_modules/ ],
                use: {
                    loader: "babel-loader"
                },
            },

            {
                test: /\.elm$/,
                exclude: [/elm-stuff/, /node_modules/],
                use: {
                    loader: "elm-webpack-loader",
                    options: {
                        cwd: "src"
                    }
                }
            }
        ],
        noParse: [/.elm$/]
    },

    plugins: [
        new CopyWebpackPlugin({
            patterns: [
                {
                    from: path.join(__dirname, "../assets/images"),
                    to: "images"
                },
                {
                    from: "./src/index.html",
                    to: "."
                },
                {
                    from: path.join(__dirname, "../assets/favicon.ico"),
                    to: "."
                }
            ]
        }),
    ],

    devServer: {
        contentBase: path.join(__dirname, "src"),
        stats: 'errors-only'
    },

};
