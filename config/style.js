const browsers = require("./browsers.json");

module.exports = isProd => {
  // assume dev/HMR values initially
  let css={ sourceMap: true }, arr=[{ loader:'style-loader' }];

  if (isProd) {
    arr = [];
    css.modules = {
      localIdentName: "[local]"
    };
    css.importLoaders = 2;
  }

  return arr.concat(
    {
      loader: "css-loader",
      options: css
    }, {
      loader: "postcss-loader",
      options: {
        sourceMap: true,
        postcssOptions: {
          plugins: [
            require("autoprefixer")()
          ]
        }
      }
    }, {
      loader: "sass-loader",
      options: {
        sourceMap: true
      }
    }
  );
};