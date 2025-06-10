// ---------------------------------------------------------------------
//
// Copyright (c) 2025 TI Tokyo    All Rights Reserved.
//
// Not for distribution or use outside of TI Tokyo.
//
// ---------------------------------------------------------------------

const path = require("path");
const { merge } = require("webpack-merge");
const webpack = require("webpack");
const config = require("./config.base.js");

module.exports = merge(config, {
    devtool: "nosources-source-map",
    devServer: {
        port: 3003,
    },
    plugins: [
        new webpack.LoaderOptionsPlugin({
            minimize: false
        }),
    ],
    module: {
        noParse: /\.min\.js$/
    }
});
