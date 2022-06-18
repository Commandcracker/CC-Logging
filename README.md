# CC-Logging

[![GitHub Pages](https://github.com/Commandcracker/CC-Logging/actions/workflows/pages.yml/badge.svg)](https://github.com/Commandcracker/CC-Logging/actions/workflows/pages.yml)

An logging library for Computer Craft

**WARNING: Please Do not use CC-Logging in production, because it's currently in development!**

- **All Handler's will be reworked.**
- **Some classes will be renamed.**
- **Log levels will completely be overhauled.**

## Example

look at the [Documentation](https://commandcracker.github.io/CC-Logging/) for moor help and please remind that the documentation is incomplete.

```lua
local logging = dofile("logging.lua")
local logger = logging.Logger.new(shell.getRunningProgram())

logger:debug("debug message")
logger:info("info message")
logger:warn("warn message")
logger:error("error message")
logger:critical("critical message")
```

### Custom Formatter

the placeholders can be seen at the [Documentation](https://commandcracker.github.io/CC-Logging/library/logging.html#v:Formatter)

```lua
logger.formatter = logging.Formatter.new("%(levelname)] %(message)")
logger:info("message with custom formatter")
```

### Handlers

```lua
local file        = fs.open("main.log", "a")
local fileHandler = logging.FileHandler.new(logger.formatter, file)
logger:addHandler(fileHandler)
logger:info("This message will be logged to main.log")
file.close() -- don't forget to close the file after your script has finished
```

```lua
local websocket        = http.websocket("ws://127.0.0.1:8080")
local websocketHandler = logging.ColordWebsocketHandler.new(logger.formatter, websocket)
logger:addHandler(websocketHandler)
logger:info("This message will be logged to ws://127.0.0.1:8080")
websocket.close() -- don't forget to close the websocket after your script has finished
```

#### Websocket Server

```js
const WebSocket = require('ws');
const server = new WebSocket.Server({
    port: 8080
});

let sockets = [];

server.on('connection', function (socket) {
    sockets.push(socket);

    // When you receive a message, log it
    socket.on('message', function (msg) {
        console.log(msg.toString());
    });

    // When a socket closes, or disconnects, remove it from the array.
    socket.on('close', function () {
        sockets = sockets.filter(s => s !== socket);
    });
});
```
