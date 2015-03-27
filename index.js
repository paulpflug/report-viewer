#!/usr/bin/env node
var program = require('commander')
  , fs = require('fs')
  , path = require('path')
  , cwd = process.cwd()
  , parsers = require('./lib/parsers')
program
  .version(JSON.parse(fs.readFileSync(path.join(__dirname, 'package.json'), 'utf8')).version)
  .usage('[options]')
  .option('--port <n>', 'port', parseInt)
  .option('--opener', 'opens a browser')
  .option('--parser <(module-)name>', 'loades a specific parser')
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

var parser;
if (program.parser) {
  if (parsers[program.parser]) {
    parser = parsers[program.parser]
  } else {
    var abs = fs.exists(program.parser) || fs.exists(program.parser + '.js');
    if (abs) program.parser = path.resolve(program.parser);
    parser = require(program.parser);
  }
} else {
  parser = parsers.spec
}
program.parser = parser

require("./lib/index.js")(program)
