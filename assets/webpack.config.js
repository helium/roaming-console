const path = require("path");
const webpack = require("webpack");
const dotenv = require("dotenv").config({
  path: path.join(__dirname, ".env"),
});

module.exports = function (env) {
  const production = process.env.NODE_ENV === "production";
  return {
    devtool: production ? "source-maps" : "eval",
    entry: "./js/app.js",
    output: {
      path: path.resolve(__dirname, "../priv/static/js"),
      filename: "[name].bundle.js",
      publicPath: "/",
    },
    module: {
      rules: [
        {
          test: /\.jsx?$/,
          exclude: /node_modules/,
          use: {
            loader: "babel-loader",
          },
        },
        {
          test: /\.css$/,
          use: ["style-loader", "css-loader"],
        },
        {
          test: /\.(png|svg|jpg|gif)$/,
          use: [
            {
              loader: "file-loader",
              options: {
                publicPath: "/js",
              },
            },
          ],
        },
      ],
    },
    resolve: {
      modules: ["node_modules", path.resolve(__dirname, "js")],
      extensions: [".js", ".jsx"],
    },
    optimization: {
      minimize: true,
      runtimeChunk: "single",
    },
    plugins: [
      new webpack.EnvironmentPlugin([
        "AUTH_0_DOMAIN",
        "AUTH_0_CLIENT_ID",
        "STRIPE_PUBLIC_KEY",
        "SELF_HOSTED",
        "MAPBOX_PRIVATE_KEY",
        "MAPBOX_STYLE_URL",
      ]),
    ],
  };
};
