# socket.io query 示例
```javascript
const socket = io({
  query: {
    token: 'cde'
  }
});
```

# angular解析查询字符串
querystring
```
var querystring = require("querystring");
querystring.parse(global.location.search&&global.location.search.substr(1)||"") 
```

