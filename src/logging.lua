--[[- An logging library for Computer Craft
    @module logging
    @usage Example:

        local logging = require("logging")
        logging:info("Message logged with logging library")

    @usage Example with logger:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        logger:info("Message logged with logging library using a logger")
]]

--[[ logging.lua
_    ____ ____ ____ _ _  _ ____  _    _  _ ____
|    |  | | __ | __ | |\ | | __  |    |  | |__|
|___ |__| |__] |__] | | \| |__] .|___ |__| |  |

Github Repository: https://github.com/Commandcracker/CC-Logging

License: 
    MIT License

    Copyright (c) 2022 Commandcracker

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
]]

--[[ todos
    TODO: improve RednetHandler and maby add a ModemHandler
    TODO: add multishell support
    TODO: rework all Handler's
    TODO: rename classses to be more descriptive
    TODO: overhaule Log levels
    TODO: global / local formatter
    TODO: add support for old computer craft versions
]]

--[[ helper functions
_  _ ____ _    ___  ____ ____
|__| |___ |    |__] |___ |__/
|  | |___ |___ |    |___ |  \
____ _  _ _  _ ____ ___ _ ____ _  _ ____
|___ |  | |\ | |     |  | |  | |\ | [__
|    |__| | \| |___  |  | |__| | \| ___]
]]

local function isinstance(object, classinfo)
    if type(object) ~= "table" then return false end
    if getmetatable(object) == nil then return false end
    return getmetatable(object).__index == classinfo
end

local function istable(object)
    return type(object) == "table"
end

local function tableConcatForamt(...)
    local fstring = ""
    for i = 0, #{ ... }, 1 do
        if i == 1 then
            fstring = "%s"
        else
            fstring = fstring .. " " .. "%s"
        end
    end
    return string.format(fstring, ...)
end

local function colorToRGB(color)
    if term.getPaletteColor then
        local r, g, b = term.getPaletteColor(color)
        return r * 255, g * 255, b * 255
    end

    -- for Computer craft blow 1.80pr1
    -- RGB values from https://tweaked.cc/module/colors.html
    local colorsRGB = {
        [colors.white]     = { 240, 240, 240 },
        [colors.orange]    = { 242, 178, 51 },
        [colors.magenta]   = { 229, 127, 216 },
        [colors.lightBlue] = { 153, 178, 242 },
        [colors.yellow]    = { 222, 222, 108 },
        [colors.lime]      = { 127, 204, 25 },
        [colors.pink]      = { 242, 178, 204 },
        [colors.gray]      = { 76, 76, 76 },
        [colors.lightGray] = { 153, 153, 153 },
        [colors.cyan]      = { 76, 153, 178 },
        [colors.purple]    = { 178, 102, 229 },
        [colors.blue]      = { 51, 102, 204 },
        [colors.brown]     = { 127, 102, 76 },
        [colors.green]     = { 87, 166, 78 },
        [colors.red]       = { 204, 76, 76 },
        [colors.black]     = { 17, 17, 17 }
    }

    return unpack(colorsRGB[color])
end

--[[ classes
____ _    ____ ____ ____ ____ ____
|    |    |__| [__  [__  |___ [__
|___ |___ |  | ___] ___] |___ ___]
]]

--[[- Holds information of an log level.
    @type Level
    @usage Example:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())
        local level   = logging.Level.new {
            name            = "My Logger",
            textcolor       = colors.orange,
            backgroundcolor = colors.blue
        }

        logger:log(level, "This message will be logged with your custom level")
]]
local Level = {
    --- Holds the log level.
    level           = 0,
    --- Holds the textcolor of the level defaults to [colors.white](https://tweaked.cc/module/colors.html#v:white)
    textcolor       = colors.white,
    --- Holds the backgroundcolor of the level defaults to [colors.black](https://tweaked.cc/module/colors.html#v:black)
    backgroundcolor = colors.black
}

--- Create's a new Level instance.
-- @tparam string name The name of the level
-- @tparam number level The level weight (optional, defaults to 0)
-- @tparam number textcolor The [textcolor](https://tweaked.cc/module/colors.html) of the level (optional, defaults to [colors.white](https://tweaked.cc/module/colors.html#v:white))
-- @tparam number backgroundcolor The [backgroundcolor](https://tweaked.cc/module/colors.html) of the level (optional, defaults to [colors.black](https://tweaked.cc/module/colors.html#v:black))
-- @treturn Level instance
function Level.new(name, level, textcolor, backgroundcolor)
    return istable(name)
        and setmetatable(name, { __index = Level })
        or setmetatable({
            name            = name,
            level           = level,
            textcolor       = textcolor,
            backgroundcolor = backgroundcolor
        }, { __index = Level })
end

--- Holds information of the message that is to be logged.
-- @type Record
local Record = {}

--- Create's a new Record instance.
-- @tparam Level level The level of the record
-- @tparam number message The message to be logged
-- @tparam number name The name of the used logger
-- @treturn Record instance
function Record.new(level, message, name)

    local instance = not isinstance(level, Level)
        and setmetatable(level, { __index = Record })
        or setmetatable({
            level   = level,
            message = message,
            name    = name
        }, { __index = Record })

    instance.time          = instance.time or os.time(os.date("*t"))
    instance.localtime     = instance.localtime or os.time(os.date("!*t"))
    instance.day           = instance.day or os.day()
    instance.computerid    = instance.computerid or os.getComputerID()
    instance.computerlabel = instance.computerlabel or os.getComputerLabel()

    return instance
end

--[[- Used to format a Record instance to a string.
    @type Formatter
    @usage Example:

        local logging   = require("logging")
        local formatter = logging.Formatter.new(
            "[%(time) %(name) %(levelname)] %(message)",
            "%Y-%m-%d %H:%M:%S"
        )

        local logger = logging.Logger.new {
            name      = shell.getRunningProgram(),
            formatter = formatter
        }

        logger:info("This message will be logged with your custom formatter")
]]
local Formatter = {
    --[[- The format string used to format the record. defaults to `[%(time) %(name) %(levelname)] %(message)`
        - placeholders:
            - `%(name)`          Name of the logger
            - `%(levelname)`     Name of the Log level
            - `%(message)`       The Message to log
            - `%(time)`          The real live time formatted by datefmt
            - `%(localtime)`     The minecraft time formatted by datefmt
            - `%(day)`           The minecraft day ([os.day()](https://tweaked.cc/module/os.html#v:day))
            - `%(computerid)`    The ID of the computer ([os.getComputerID()](https://tweaked.cc/module/os.html#v:getComputerID))
            - `%(computerlabel)` The label of the computer ([os.getComputerLabel()](https://tweaked.cc/module/os.html#v:getComputerLabel))
            - `%(thread)`        The memory address of the current thread
    ]]
    fmt     = "[%(time) %(levelname) %(computerid)] %(message)",
    --- The date format, it works like the format in [os.date()](https://tweaked.cc/module/os.html#v:date)
    datefmt = "%H:%M:%S"
}

--- Create's a new Formatter instance.
-- @tparam string fmt The format string
-- @tparam string datefmt The format string for the date
-- @treturn Formatter instance
function Formatter.new(fmt, datefmt)
    return istable(fmt)
        and setmetatable(fmt, { __index = Formatter })
        or setmetatable({
            fmt     = fmt,
            datefmt = datefmt
        }, { __index = Formatter })
end

--- Formats a Record instance to a string.
-- @tparam Record record The record to format
-- @treturn string The formatted string
function Formatter:format(record)
    local temp = self.fmt

    temp = temp:gsub("%%%(name%)", record.name)
    temp = temp:gsub("%%%(levelname%)", record.level.name)
    temp = temp:gsub("%%%(message%)", record.message)
    temp = temp:gsub("%%%(time%)", os.date(self.datefmt, record.time))
    temp = temp:gsub("%%%(localtime%)", os.date(self.datefmt, record.localtime))
    temp = temp:gsub("%%%(day%)", record.day)
    temp = temp:gsub("%%%(computerid%)", record.computerid)
    temp = temp:gsub("%%%(thread%)", tostring(coroutine.running()):sub(9))

    if record.computerlabel then
        temp = temp:gsub("%%%(computerlabel%)", record.computerlabel)
    else
        temp = temp:gsub("%%%(computerlabel%)", "")
    end

    return temp
end

--[[ handlers
_  _ ____ _  _ ___  _    ____ ____ ____
|__| |__| |\ | |  \ |    |___ |__/ [__
|  | |  | | \| |__/ |___ |___ |  \ ___]
]]

--[[- broadcast the formatted record message with rednet.
    @type RednetHandler
    @usage Example:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        rednet.open("right") -- replace "right" with the side your modem is connected to
        local rednetHandler = logging.RednetHandler.new(logger.formatter)
        logger:addHandler(rednetHandler)

        logger:info("This message will be send over rednet")
]]
local RednetHandler = {
    --- Holds the channel where the message is to be send defaults to [rednet.CHANNEL_BROADCAST](https://tweaked.cc/module/rednet.html#v:CHANNEL_BROADCAST)
    channel  = rednet.CHANNEL_BROADCAST,
    --- Holds the rednet protocol that should be used
    protocol = "logging"
}

--- Create's a new RednetHandler instance.
-- @tparam Formatter formatter The formatter to use
-- @tparam number channel or the computer ID to send the message to (optional, defaults to [rednet.CHANNEL_BROADCAST](https://tweaked.cc/module/rednet.html#v:CHANNEL_BROADCAST))
-- @tparam string protocol The protocol to use (optional, defaults to "logging")
-- @treturn RednetHandler instance
function RednetHandler.new(formatter, channel, protocol)
    return not isinstance(formatter, Formatter)
        and setmetatable(formatter, { __index = RednetHandler })
        or setmetatable({
            formatter = formatter,
            channel   = channel,
            protocol  = protocol
        }, { __index = RednetHandler })
end

--- Handles a record.
-- @tparam Record record The record to handle.
function RednetHandler:handle(record)
    --record.formatter = self.formatter
    rednet.send(self.channel, record, self.protocol)
end

--[[- Will send the formatted record message to a websocket.
    @type WebsocketHandler
    @usage Example:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        local websocket = http.websocket("ws://localhost:8080/")
        -- replace "localhost:8080" with the address of your websocket server
        local websocketHandler = logging.WebsocketHandler.new(logger.formatter, websocket)
        logger:addHandler(websocketHandler)

        logger:info("This message will be sent to the websocket")

        websocket.close() -- don't forget to close the websocket after your script has finished
]]
local WebsocketHandler = {}

--- Create's a new WebsocketHandler instance.
-- @tparam Formatter formatter The formatter to use
-- @param websocket [Websocket](https://tweaked.cc/module/http.html#ty:Websocket) The websocket to send the message to.
-- @treturn WebsocketHandler instance
function WebsocketHandler.new(formatter, websocket)
    return not isinstance(formatter, Formatter)
        and setmetatable(formatter, { __index = WebsocketHandler })
        or setmetatable({
            formatter = formatter,
            websocket = websocket
        }, { __index = WebsocketHandler })
end

--- Handles a record.
-- @tparam Record record The record to handle.
function WebsocketHandler:handle(record)
    self.websocket.send(self.formatter:format(record))
end

--[[- Will send the record with the used formatter to a websocket.
    @type RawWebsocketHandler
    @usage Example:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        local websocket = http.websocket("ws://localhost:8080/")
        -- replace "localhost:8080" with the address of your websocket server
        local rawWebsocketHandler = logging.RawWebsocketHandler.new(logger.formatter, websocket)
        logger:addHandler(rawWebsocketHandler)

        logger:info("This message will be sent to the websocket in raw format")

        websocket.close() -- don't forget to close the websocket after your script has finished
]]
local RawWebsocketHandler = {}

--- Create's a new RawWebsocketHandler instance.
-- @tparam Formatter formatter The formatter to use
-- @param websocket [Websocket](https://tweaked.cc/module/http.html#ty:Websocket) The websocket to send the message to.
-- @treturn RawWebsocketHandler instance
function RawWebsocketHandler.new(formatter, websocket)
    return not isinstance(formatter, Formatter)
        and setmetatable(formatter, { __index = RawWebsocketHandler })
        or setmetatable({
            formatter = formatter,
            websocket = websocket
        }, { __index = RawWebsocketHandler })
end

--- Handles a record.
-- @tparam Record record The record to handle.
function RawWebsocketHandler:handle(record)
    record.formatter = self.formatter
    self.websocket.send(record)
end

--[[- Will send the formatted record message with [24-bit/true Colors in ansi escape codes](https://en.wikipedia.org/wiki/ANSI_escape_code#24-bit) to a websocket.
    @type ColordWebsocketHandler
    @usage Example:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        local websocket = http.websocket("ws://localhost:8080/")
        -- replace "localhost:8080" with the address of your websocket server
        local colordWebsocketHandler = logging.ColordWebsocketHandler.new(logger.formatter, websocket)
        logger:addHandler(colordWebsocketHandler)

        logger:info("This message will be sent to the websocket with its color in ansi escape codes")

        websocket.close() -- don't forget to close the websocket after your script has finished
]]
local ColordWebsocketHandler = {}

--- Create's a new ColordWebsocketHandler instance.
-- @tparam Formatter formatter The formatter to use
-- @param websocket [Websocket](https://tweaked.cc/module/http.html#ty:Websocket) The websocket to send the message to.
-- @treturn ColordWebsocketHandler instance
function ColordWebsocketHandler.new(formatter, websocket)
    return not isinstance(formatter, Formatter)
        and setmetatable(formatter, { __index = ColordWebsocketHandler })
        or setmetatable({
            formatter = formatter,
            websocket = websocket
        }, { __index = ColordWebsocketHandler })
end

--- Handles a record.
-- @tparam Record record The record to handle.
function ColordWebsocketHandler:handle(record)
    local fr, fg, fb = colorToRGB(record.level.textcolor)
    local br, bg, bb = colorToRGB(record.level.backgroundcolor)

    self.websocket.send(
        "\27[38;2;" .. fr .. ";" .. fg .. ";" .. fb .. "m" ..
        "\27[48;2;" .. br .. ";" .. bg .. ";" .. bb .. "m" ..
        self.formatter:format(record) ..
        "\27[39m" ..
        "\27[49m"
    )
end

--[[- An FileHandler that writes to a file.
    @type FileHandler
    @usage Example:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        local file = fs.open("example.log", "a")
        -- replace "example.log" with the path of your log file
        local fileHandler = logging.FileHandler.new(logger.formatter, file)
        logger:addHandler(fileHandler)

        logger:info("This message will be sent to the file")

        file.close() -- don't forget to close the file after your script has finished
]]
local FileHandler = {}

--- Create's a new FileHandler instance.
-- @tparam Formatter formatter The formatter to use.
-- @tparam table file The file to write to. (use [fs.open](https://tweaked.cc/module/fs.html#v:open) to open a file)
-- @treturn FileHandler instance
function FileHandler.new(formatter, file)
    return not isinstance(formatter, Formatter)
        and setmetatable(formatter, { __index = FileHandler })
        or setmetatable({
            formatter = formatter,
            file = file
        }, { __index = FileHandler })
end

--- Handles a record.
-- @tparam Record record The record to handle.
function FileHandler:handle(record)
    self.file.writeLine(self.formatter:format(record))
end

--[[- An Handler that writes to the terminal.
    @type TerminalHandler
    @usage Example:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        -- the logger will have a TerminalHandler by default
        -- but if you want to add another one you can do it like this:
            -- local terminalHandler = logging.TerminalHandler.new(logger.formatter)
            -- logger:addHandler(terminalHandler)

        logger:info("This message will be sent to the terminal")
]]
local TerminalHandler = {}

--- Create's a new TerminalHandler instance.
-- @tparam Formatter formatter The formatter to use.
-- @treturn TerminalHandler instance
function TerminalHandler.new(formatter)
    return setmetatable({ formatter = formatter }, { __index = TerminalHandler })
end

--- Handles a record.
-- @tparam Record record The record to handle.
function TerminalHandler:handle(record)
    local old_text_color       = term.getTextColor()
    local old_background_color = term.getBackgroundColor()

    term.setTextColor(record.level.textcolor)
    term.setBackgroundColor(record.level.backgroundcolor)

    write(self.formatter:format(record))

    term.setTextColor(old_text_color)
    term.setBackgroundColor(old_background_color)

    write("\n")
end

--[[ recievers
____ ____ ____ _ ____ _  _ ____ ____ ____
|__/ |___ |    | |___ |  | |___ |__/ [__
|  \ |___ |___ | |___  \/  |___ |  \ ___]
]]

--[[- An Reciever that recives messages from Rednet.
    @type RednetReciever
    @usage Example limited to a single channel and no background process:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        local rednetReciever = logging.RednetReciever.new()

        while true do
            rednetReciever:receive(logger)
        end
    
    @usage Example with coroutine's:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        local rednetReciever = logging.RednetReciever.new()
        logger:addReciever(rednetReciever)

        -- the main loop can be modified to do all kinds of stuff.
        local main_loop = coroutine.create(function()
            while true do
                logger:info("im very useful")
                sleep(5)
            end
        end)

        local coroutines = logger:getRecieverCoroutines()
        table.insert(coroutines, main_loop)

        while true do
            local tEventData = table.pack(os.pullEventRaw())

            for _, c in pairs(coroutines) do
                coroutine.resume(c, table.unpack(tEventData))
            end
        end
]]
local RednetReciever = {
    --- Holds the rednet protocol that should be used
    protocol = "logging"
}

--- Create's a new RednetReciever instance.
-- @tparam string protocol The protocol to listen to. (optional, defaults to "logging")
-- @treturn RednetReciever instance
function RednetReciever.new(protocol)
    return setmetatable({ protocol = protocol }, { __index = RednetReciever })
end

--- Recives message from rednet.
-- @tparam Logger logger The logger to use.
function RednetReciever:receive(logger)
    -- local id, message, protocol = rednet.receive(self.protocol)
    local _, message = rednet.receive(self.protocol)

    local record = setmetatable(message, { __index = Record })
    record.level = setmetatable(record.level, { __index = Level })
    --local formatter = setmetatable(message.formatter, { __index = Formatter })

    logger:handel(record)
end

--[[ logger
_    ____ ____ ____ ____ ____
|    |  | | __ | __ |___ |__/
|___ |__| |__] |__] |___ |  \
]]

--[[- Holds all functions related to logging.
    @type Logger
    @usage Example:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        logger:info("This message will be logged")
]]
local Logger = {
    --- The level that the logger will log at.
    level     = 0,
    --- Holds all recievers
    recievers = {}
}

--- Create's a new Logger instance.
-- @tparam string name The logger name.
-- @tparam number level The level weight.
-- @tparam Formatter formatter The formatter to use.
-- @treturn Logger instance
function Logger.new(name, level, formatter)

    local instance = istable(name)
        and setmetatable(name, { __index = Logger })
        or setmetatable({
            name = name,
            level = level,
            formatter = formatter
        }, { __index = Logger })

    instance.formatter = instance.formatter or Formatter.new()

    instance.defaultHandler = instance.defaultHandler or TerminalHandler.new(instance.formatter)
    instance.handlers       = instance.handlers or { instance.defaultHandler }

    instance.levels = instance.levels or {
        DEBUG    = Level.new("DEBUG", 10, colors.cyan),
        INFO     = Level.new("INFO", 20, colors.green),
        WARN     = Level.new("WARN", 30, colors.yellow),
        ERROR    = Level.new("ERROR", 40, colors.red),
        CRITICAL = Level.new("CRITICAL", 50, colors.magenta)
    }

    return instance
end

--- Adds a new handler to the logger.
-- @tparam table handler The handler to add.
function Logger:addHandler(handler)
    table.insert(self.handlers, handler)
end

--- Removes the given handler from the logger. dont forget to close files, websockets, etc.
-- @tparam table handler The handler to remove.
function Logger:removeHandler(handler)
    for i, h in pairs(self.handlers) do
        if h == handler then
            table.remove(self.handlers, i)
        end
    end
end

--- This function adds a level to the internal levels list of the logger. currently this function is useless since you dont need to add levels for them to work.
-- @tparam Level level The level.
function Logger:registerLevel(level)
    self.levels[level.name] = level
end

--- Removes the default TerminalHandler from the logger.
function Logger:removeDefaultHandler()
    if self.defaultHandler then
        for i, h in pairs(self.handlers) do
            if h == self.defaultHandler then
                table.remove(self.handlers, i)
            end
        end
        self.defaultHandler = nil
    end
end

--- Handels a record.
-- @tparam Record record The record to handle.
function Logger:handel(record)
    for i = 1, #self.handlers, 1 do
        self.handlers[i]:handle(record)
    end
end

--- logs a message
-- @tparam Level level the level of the message
-- @tparam string ... The arguments to log
function Logger:log(level, ...)
    local msg    = tableConcatForamt(...)
    local record = Record.new(level, msg, self.name)

    self:handel(record)
end

--- add a reciever to the logger
-- @tparam table reciever the reciever to add
function Logger:addReciever(reciever)
    table.insert(self.recievers, reciever)
end

--[[- Returns coroutines for all recievers that recive messages.
    @treturn table coroutines
    @usage Example:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        -- in this example we have a reciever that recives messages from rednet
        local rednetReciever = logging.RednetReciever.new()
        logger:addReciever(rednetReciever)
        
        -- the main loop can be modified to do all kinds of stuff.
        local main_loop = coroutine.create(function()
            while true do
                logger:info("im very useful")
                sleep(5)
            end
        end)

        local coroutines = logger:getRecieverCoroutines()
        table.insert(coroutines, main_loop)

        while true do
            local tEventData = table.pack(os.pullEventRaw())

            for _, c in pairs(coroutines) do
                coroutine.resume(c, table.unpack(tEventData))
            end
        end
]]
function Logger:getRecieverCoroutines()
    local coroutines = {}
    for i = 1, #self.recievers, 1 do
        table.insert(coroutines, coroutine.create(function()
            while true do
                self.recievers[i]:receive(self)
            end
        end))
    end
    return coroutines
end

--- logs a message at the debug level
-- @tparam string ... The arguments to log
function Logger:debug(...)
    self:log(self.levels.DEBUG, ...)
end

--- logs a message at the info level
-- @tparam string ... The arguments to log
function Logger:info(...)
    self:log(self.levels.INFO, ...)
end

--- logs a message at the warn level
-- @tparam string ... The arguments to log
function Logger:warn(...)
    self:log(self.levels.WARN, ...)
end

--- logs a message at the error level
-- @tparam string ... The arguments to log
function Logger:error(...)
    self:log(self.levels.ERROR, ...)
end

--- logs a message at the critical level
-- @tparam string ... The arguments to log
function Logger:critical(...)
    self:log(self.levels.CRITICAL, ...)
end

local rootLogger = Logger.new("root")

local logging = {}

--- logs a message at the debug level
-- @tparam string ... The arguments to log
function logging.debug(...)
    rootLogger:debug(...)
end

--- logs a message at the info level
-- @tparam string ... The arguments to log
function logging.info(...)
    rootLogger:info(...)
end

--- logs a message at the warn level
-- @tparam string ... The arguments to log
function logging.warn(...)
    rootLogger:warn(...)
end

--- logs a message at the error level
-- @tparam string ... The arguments to log
function logging.error(...)
    rootLogger:error(...)
end

--- logs a message at the critical level
-- @tparam string ... The arguments to log
function logging.critical(...)
    rootLogger:critical(...)
end

--- logs a message
-- @tparam Level level the level of the message
-- @tparam string ... The arguments to log
function logging.log(level, ...)
    rootLogger:log(level, ...)
end

--- Hols the levels of the root logger
logging.levels = rootLogger.levels

-- Classes
logging.Level     = Level
logging.Record    = Record
logging.Formatter = Formatter
logging.Logger    = Logger

-- Handlers
logging.TerminalHandler        = TerminalHandler
logging.FileHandler            = FileHandler
logging.WebsocketHandler       = WebsocketHandler
logging.ColordWebsocketHandler = ColordWebsocketHandler
logging.RawWebsocketHandler    = RawWebsocketHandler
logging.RednetHandler          = RednetHandler

-- Recievers
logging.RednetReciever = RednetReciever

return logging
