const browsers = require("./browsers.json");

module.exports = {
  babelrc: false,
  presets: [
    [
      "@babel/preset-env",
      {
        loose: true,
        modules: false,
        targets: browsers
      }
    ]
  ],
  plugins: [
    "@babel/plugin-transform-object-assign",
    ["@babel/plugin-proposal-decorators", { legacy: true }],
    ["@babel/plugin-transform-react-jsx", { pragma: "h" }],
    "@babel/plugin-transform-react-constant-elements"
  ]
};