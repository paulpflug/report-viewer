#!/usr/bin/env node
var program = require('commander')

program
.version('0.0.1')
.option('--port <n>', 'Port', parseInt)
.option('--livereload <n>', 'Port for the liveconnect Server', parseInt)
.option('--opener', 'If given starts a browser')
.option('--reporter', 'default xunit')
.parse(process.argv);

require("./lib/index.js")(program)
