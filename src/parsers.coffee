events = require "events"
xmlparser = require("xml2json").toJson

module.exports = {
  json: (readable) ->
    actions = new events.EventEmitter()
    readable.on "readable", () ->
      chunk = readable.read()
      if chunk != null
        data = false
        try
          data = JSON.parse(chunk)    
        if data
          actions.emit "dataChunk", data
        else
          actions.emit "dataConsole", chunk
    return actions
  xunit: (readable) ->
    actions = new events.EventEmitter()
    buffer = ""
    parse = () ->
      rawData = xmlparser(buffer,{object:true})
      data = [["start",{"total":rawData.testsuite.tests}]]
      for test in rawData.testsuite.testcase
        item = {
          title: test.name
          fullTitle: test.classname + " "+ test.name
          duration: test.time*1000
        }
        if test.failure
          item.failure = test.failure
          .replace(/&amp;lt;/g,"<")
          .replace(/&amp;gt;/g,">")
          .replace(/&amp;&amp;#35;40;/g,"(")
          .replace(/&amp;&amp;#35;41;/g,")")
          .replace(/&apos;/g,"'")
          item = ["fail",item]
        else
          item = ["pass",item]
        data.push(item)
      data.push(["end",{
        tests: rawData.testsuite.tests
        failures: rawData.testsuite.failures            
        duration: rawData.testsuite.time*1000
        }])
      actions.emit "data", data
    readable.on "readable", () ->
      chunk = readable.read()
      if chunk != null
        match = false
        if /^<testsuite/.test(chunk)
          buffer = chunk
        else if /^<testcase/.test(chunk)
          buffer += chunk
          if /<\/testsuite>/.test(chunk)
            parse()
        else if /^<\/testsuite>/.test(chunk)
          buffer += chunk
          parse()
        else
          actions.emit "dataConsole", chunk
    return actions
}