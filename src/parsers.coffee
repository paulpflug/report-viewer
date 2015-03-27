
xmlparser = require("xml2json").toJson

datetimeRegex = /^(?:\s*(Sun|Mon|Tue|Wed|Thu|Fri|Sat),\s*)?(0?[1-9]|[1-2][0-9]|3[01])\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(19[0-9]{2}|[2-9][0-9]{3}|[0-9]{2})\s+(2[0-3]|[0-1][0-9]):([0-5][0-9])(?::(60|[0-5][0-9]))?\s+([-\+][0-9]{2}[0-5][0-9]|(?:UT|GMT|(?:E|C|M|P)(?:ST|DT)|[A-IK-Z]))\s*/

getDuration = (string) ->
  duration = string.match(/\((\d+m?s)\)/)
  duration = duration[1] if duration
  return duration

module.exports = {
  spec: (actions,readable) ->
    levels = []
    indent = 0
    inTest = true
    inError = 0
    error = {}
    tests = 0
    started = false
    readable.on "data", (chunk) ->
      if chunk != null
        if chunk.indexOf("\u001b")> -1
          actions.emit "dataChunk", ["start",{}]
          started = true
          levels = []
          indent = 0
          tests = 0
          inTest = true
          inError = 0
        else
          if not started
            actions.emit "dataChunk", ["start",{}] 
            started = true
          lines = chunk.split("\n")
          lines.pop() if lines[lines.length-1] == ""
          for line in lines
            if line != ""
              currentIndent = line.match(/(^\s*)/)[1].length
              if currentIndent > 1
                name = line.substring(currentIndent)
                if inTest
                  
                  if name[0] == "✓" # successful test 
                    
                    name = name.substring(2)
                    tests++
                    actions.emit "dataChunk", ["pass",{
                      title: name
                      fullTitle: levels.join(" ") + " "+ name
                      levels: levels.slice()
                      duration: getDuration(name)
                    }]
                    actions.emit "consoleChunk", {text:line,type:"pass"}
                  else if name.search(/^\d+\)/) > -1 # failed test
                    id = name.match(/(^\d+)\)/)[1]
                    name = name.replace(/^\d+\)/, "")
                    tests++
                    actions.emit "dataChunk", ["fail",{
                      title: name
                      fullTitle: levels.join(" ") + " "+ name
                      levels: levels.slice()
                      failure: id
                      duration: getDuration(name)
                    }]
                    actions.emit "consoleChunk", {text:line,type:"fail"}
                  else if name.search(/^\d+ passing/) > -1 # end test
                    inTest = false
                    data = line.match(/(\d+) passing \((\d+)ms\)/)
                    actions.emit "dataChunk", ["end",{
                      tests: tests
                      duration: getDuration(name)
                      }]
                    actions.emit "consoleChunk", {text:line,type:"normal"}
                  else  # level
                    if currentIndent > indent
                      levels.push name
                    else if currentIndent == indent
                      levels[levels.length-1] = name
                    else
                      removecount = (indent - currentIndent)/2
                      levels.splice levels.length - removecount, removecount
                      levels[levels.length-1] = name
                    indent = currentIndent
                    actions.emit "consoleChunk", {text:line,type:"level"}
                else
                  if inError and name
                    error.text.push name
                    inError++
                  else if inError
                    inError = 0
                    actions.emit "errorChunk", error
                  else if name.search(/^\d+\)/) > -1 # failed test
                    id = name.match(/(^\d+)\)/)[1]
                    error = {id: id, text:[] }
                    inError = 1
                  if inError == 2
                    actions.emit "consoleChunk", {text:line,type:"error"}
                  else
                    actions.emit "consoleChunk", {text:line,type:"normal"}
              else
                type ="normal"
                if line.search(datetimeRegex) > -1
                  line = line.replace(datetimeRegex,"")
                  type ="stderr"
                actions.emit "consoleChunk", {text:line,type:type}
            else
              actions.emit "consoleChunk", {text:line,type:"normal"}
              if inError
                inError = 0
                actions.emit "errorChunk", error
  json: (actions,readable) ->
    readable.on "readable", () ->
      chunk = readable.read()
      if chunk != null
        data = false
        try
          data = JSON.parse(chunk)    
        if data
          actions.emit "dataChunk", data
        else
          actions.emit "consoleChunk", {text:chunk}
  xunit: (actions,readable) ->
    buffer = ""
    parse = () ->
      rawData = xmlparser(buffer,{object:true})
      data = [["start",{"total":rawData.testsuite.tests}]]
      for test in rawData.testsuite.testcase
        item = {
          title: test.name
          fullTitle: test.classname + " "+ test.name
          duration: test.time*1000+"ms"
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
          actions.emit "consoleChunk", {text:chunk}
}