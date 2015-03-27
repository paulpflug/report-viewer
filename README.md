![](https://raw.githubusercontent.com/paulpflug/report-viewer/gh-pages/report-viewer.png)
# report-viewer

A cli for piping a unit test result directly into your browser.
Currently only works with mocha and the spec reporter.

Each time a test result is piped into stdio, the browser view will be updated.
Uses [socket.io](http://socket.io/) for best experience.

No livereload needed.
Errors will be shown prominently on top.

The console output will be visible in the side of the browser

## Install

```sh
npm install report-viewer

```

## Usage
Best used with mocha:
```sh
mocha --watch 2>&1 | report-viewer --opener
```
This will start a webserver (localhost:9999) to view current testresults.

Available options:
```
-h, --help                output usage information
-V, --version             output the version number
--port <n>                port
--opener                  opens a browser
--parser <(module-)name>  loades a specific parser
--viewer <(module-)name>  loades a specific viewer
```

## Views

You can use your own view by cloning the [report-viewer-default](https://github.com/paulpflug/report-viewer-default) repository, rename and change it.
both should work:
```sh
mocha --watch 2>&1 | report-viewer --viewer your-view
mocha --watch 2>&1 | report-viewer --viewer /path/to/your-view
```

If you publish your work, let me know, I will link it up

## Testing

See the [report-viewer-tester](https://github.com/paulpflug/report-viewer-tester) repository

## Release History
 - *v0.2.0*: 
    reworked the view

    using spec reporter now

    works with debug and console output directly into the browser window
 - *v0.1.1*: modified dependencies
 - *v0.1.0*: 
   Moved the view into seperate bundle [report-viewer-default](https://github.com/paulpflug/report-viewer-default)

   Largely improved the view

   Console output is piped into the console of the browser

   Cut on dependencies

 - *v0.0.2*: Rename to report-viewer
 - *v0.0.1*: First Release

## License
Copyright (c) 2015 Paul Pflugradt
Licensed under the MIT license.
