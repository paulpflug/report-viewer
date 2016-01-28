#!/usr/bin/env node
var program = require('commander')
  , fs = require('fs')
  , path = require('path')
  , cwd = process.cwd()
program
  .version(JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'), 'utf8')).version)
  .usage('[options] [command...]')
  .option('--port <n>', 'port', parseInt)
  .option('--opener', 'opens a browser')
  .option('--viewer <(module-)name>', 'loades a specific viewer')
  .parse(process.argv);

module.paths.push(cwd, path.join(cwd, 'node_modules'));

var viewer;
if (program.viewer) {
  var abs = fs.exists(program.viewer) || fs.exists(program.viewer + '.js');
  if (abs) program.viewer = path.resolve(program.viewer);
  viewer = require(program.viewer);
} else {
  viewer = require("report-viewer-default")
}
program.viewer = viewer

require("./lib/index.js")(program)
