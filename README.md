# mocha-report-viewer

A cli for piping a mocha xunit testresult directly into your browser.
Each time mocha runs tests, the browser view will be updated.
Uses [socket.io](http://socket.io/) for best experience.


## Install

```sh
npm install mocha-report-viewer

```

## Usage
Best used with mocha:
```sh
mocha --reporter xunit --watch | livereport --opener
```
This will start a webserver (localhost:9999) to view current testresults.
No livereload needed.
Errors will be shown prominently on top.

## Release History

 - *v0.0.1*: First Release

## License
Copyright (c) 2015 Paul Pflugradt
Licensed under the MIT license.