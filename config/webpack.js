const { join } = require("path");
const webpack = require("webpack");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const TerserPlugin = require("terser-webpack-plugin");

const Jarvis = require("../src/server");
const pkg = require("../package.json");

const babel = require("./babel");
const styles = require("./style");
const uglify = require("./uglify.json");

const dist = join(__dirname, "../dist");

module.exports = env => {
  const isProd = env && env.production;

  // Our style-loader chain
  const cssGroup = styles(isProd);

  // Our entry file
  let entry = "./src/client/index.js";

  // Base plugins
  let plugins = [
    new webpack.DefinePlugin({
      "process.env.NODE_ENV": JSON.stringify(
        isProd ? "production" : "development"
      )
    })
  ];

  if (isProd) {
    babel.plugins.push("babel-plugin-transform-react-remove-prop-types");
    plugins.push(
      new MiniCssExtractPlugin({
        filename: "style.css"
      })
    );
  } else {
    // Add HMR client
    entry = [
      "webpack-hot-middleware/client?path=/__webpack_hmr&timeout=20000",
      entry
    ];
    // Add dev-only plugins
    plugins.push(
      new webpack.HotModuleReplacementPlugin(),
      new Jarvis()
    );
  }

  return {
    mode: isProd ? "production" : "development",
    entry,
    output: {
      path: dist,
      publicPath: "/",
      filename: "bundle.js"
    },
    resolve: {
      extensions: [".jsx", ".js", ".json", ".scss"],
      alias: {
        react: "preact/compat",
        "react-dom": "preact/compat"
      }
    },
    plugins,
    devtool: !isProd && "eval-source-map",
    optimization: isProd ? {
      minimize: true,
      minimizer: [
        new TerserPlugin({
          terserOptions: uglify
        })
      ]
    } : {},
    module: {
      rules: [
        {
          test: /\.jsx?$/,
          include: join(__dirname, "../src"),
          use: {
            loader: "babel-loader",
            options: babel
          }
        },
        {
          test: /(\.css|\.scss)$/,
          use: isProd
            ? [MiniCssExtractPlugin.loader, ...cssGroup.slice(1)]
            : cssGroup
        },
        {
          test: /\.(xml|html|txt|md)$/,
          type: "asset/source"
        },
        {
          test: /\.ico$/,
          type: "asset/inline"
        },
        {
          test: /\.svg$/,
          use: {
            loader: "svg-url-loader",
            options: {}
          }
        }
      ]
    }
  };
};
