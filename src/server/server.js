/*!
 * webpack-jarvis <https://github.com/zouhir/webpack-jarvis>
 *
 * Copyright (c) 2017, Zouhir C.
 * Licensed under the MIT License.
 */

const polka = require("polka");
const socket = require("socket.io");
const statics = require("serve-static");
const { join } = require("path");

const client = join(__dirname, "..");

exports.init = (compiler, isDev) => {
  const http = require('http');
  const app = polka().use(statics(client));

  if (isDev) {
    app.use(
      require("webpack-dev-middleware")(compiler, {
        publicPath: '/',
        stats: 'errors-warnings',
        logLevel: 'info'
      }),
      require("webpack-hot-middleware")(compiler, {
        heartbeat: 1e4, // 10s
        path: "/__webpack_hmr",
        reload: true
      })
    );
  }
  
  // Create HTTP server with polka handler
  const server = http.createServer(app.handler);
  const io = socket(server);
  
  return { http: server, io };
};
