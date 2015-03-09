# report-viewer

A cli for piping a unit test result directly into your browser.
Currently only works with mocha and the xunit reporter.

Each time a test result is piped into stdio, the browser view will be updated.
Uses [socket.io](http://socket.io/) for best experience.


## Install

```sh
npm install report-viewer

```

## Usage
Best used with mocha:
```sh
mocha --reporter xunit --watch | report-viewer --opener
```
This will start a webserver (localhost:9999) to view current testresults.
No livereload needed.
Errors will be shown prominently on top.

## Release History

 - *v0.0.2*: Rename to report-viewer
 - *v0.0.1*: First Release

## License
Copyright (c) 2015 Paul Pflugradt
Licensed under the MIT license.