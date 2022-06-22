--[[- An logging library for Computer Craft
    @module logging
    @usage Example:

        local logging = require("logging")
        logging:info("Message logged with logging library")

    Example with logger:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        logger:info("Message logged with logging library using a logger")
]]

--[[
    TODO: improve RednetHandler
    TODO: create RednetReciever
    TODO: add multishell support
    TODO: rework all Handler's
    TODO: rename classses to be more descriptive
    TODO: overhaule Log levels
]]

--[[- Holds information of an log level.
    @type Level
    @usage Example:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())
        local level   = logging.Level.new("My Logger", nil, colors.orange, colors.blue)

        logger:log(level, "This message will be logged with your custom level")
]]
local Level = {}

--- Create's a new Level instance.
-- @tparam string name The name of the level
-- @tparam number level The level weight (optional, defaults to 0)
-- @tparam number textcolor The [textcolor](https://tweaked.cc/module/colors.html) of the level (optional, defaults to [colors.white](https://tweaked.cc/module/colors.html#v:white))
-- @tparam number backgroundcolor The [backgroundcolor](https://tweaked.cc/module/colors.html) of the level (optional, defaults to [colors.black](https://tweaked.cc/module/colors.html#v:black))
-- @treturn Level instance
function Level.new(name, level, textcolor, backgroundcolor)
    local instance           = setmetatable({}, { __index = Level })
    instance.name            = name
    instance.level           = level or 0
    instance.textcolor       = textcolor or colors.white
    instance.backgroundcolor = backgroundcolor or colors.black
    return instance
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
    local instance         = setmetatable({}, { __index = Record })
    instance.level         = level
    instance.message       = message
    instance.time          = os.time(os.date("*t"))
    instance.localtime     = os.time(os.date("!*t"))
    instance.name          = name
    instance.day           = os.day()
    instance.computerid    = os.getComputerID()
    instance.computerlabel = os.getComputerLabel()
    return instance
end

--[[- Formats a Record instance to a string.
    - fmt placeholders: 
        - `%(name)`          Name of the logger
        - `%(levelname)`     Name of the Log level
        - `%(message)`       The Message to log
        - `%(time)`          The real live time formatted by datefmt
        - `%(localtime)`     The minecraft time formatted by datefmt
        - `%(day)`           The minecraft day ([os.day()](https://tweaked.cc/module/os.html#v:day))
        - `%(computerid)`    The ID of the computer ([os.getComputerID()](https://tweaked.cc/module/os.html#v:getComputerID))
        - `%(computerlabel)` The label of the computer ([os.getComputerLabel()](https://tweaked.cc/module/os.html#v:getComputerLabel))
    - datefmt works like the format in [os.date()](https://tweaked.cc/module/os.html#v:date)
    @type Formatter
    @usage Example:

        local logging   = require("logging")
        local formatter = logging.Formatter.new("[%(time) %(name) %(levelname)] %(message)", "%Y-%m-%d %H:%M:%S")
        local logger    = logging.Logger.new(shell.getRunningProgram(), nil, formatter)

        logger:info("This message will be logged with your custom formatter")
]]
local Formatter = {}

--- Create's a new Formatter instance.
-- @tparam string fmt The format string
-- @tparam string datefmt The format string for the date
-- @treturn Formatter instance
function Formatter.new(fmt, datefmt)
    local instance   = setmetatable({}, { __index = Formatter })
    instance.fmt     = fmt or "[%(time) %(levelname)] %(message)"
    instance.datefmt = datefmt or "%H:%M:%S"
    return instance
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

    if record.computerlabel then
        temp = temp:gsub("%%%(computerlabel%)", record.computerlabel)
    else
        temp = temp:gsub("%%%(computerlabel%)", "")
    end

    return temp
end

--[[- broadcast the formatted record message with rednet.
    @type RednetHandler
    @usage Example:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        rednet.open("right") -- replace "right" with the side your modem is connected to
        local rednetHandler = logging.RednetHandler.new(logger.formatter)
        logger:addHandler(rednetHandler)

        logger:info("This message will be broadcasted over rednet")
]]
local RednetHandler = {}

--- Create's a new RednetHandler instance.
-- @tparam Formatter formatter The formatter to use
-- @treturn RednetHandler instance
function RednetHandler.new(formatter)
    local instance     = setmetatable({}, { __index = RednetHandler })
    instance.formatter = formatter
    return instance
end

--- Handles a record.
-- @tparam Record record The record to handle.
function RednetHandler:handle(record)
    rednet.broadcast(self.formatter:format(record))
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
    local instance     = setmetatable({}, { __index = WebsocketHandler })
    instance.websocket = websocket
    instance.formatter = formatter
    return instance
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
    local instance     = setmetatable({}, { __index = RawWebsocketHandler })
    instance.websocket = websocket
    instance.formatter = formatter
    return instance
end

--- Handles a record.
-- @tparam Record record The record to handle.
function RawWebsocketHandler:handle(record)
    record.formatter = self.formatter
    self.websocket.send(record)
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
    local instance     = setmetatable({}, { __index = ColordWebsocketHandler })
    instance.websocket = websocket
    instance.formatter = formatter
    return instance
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
    local instance     = setmetatable({}, { __index = FileHandler })
    instance.file      = file
    instance.formatter = formatter
    return instance
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
    local instance     = setmetatable({}, { __index = TerminalHandler })
    instance.formatter = formatter
    return instance
end

--- Handles a record.
-- @tparam Record record The record to handle.
function TerminalHandler:handle(record)
    local old_text_colour       = term.getTextColor()
    local old_background_colour = term.getBackgroundColor()

    term.setTextColor(record.level.textcolor)
    term.setBackgroundColor(record.level.backgroundcolor)

    write(self.formatter:format(record))

    term.setTextColor(old_text_colour)
    term.setBackgroundColor(old_background_colour)

    write("\n")
end

--[[- Holds all functions related to logging.
    @type Logger
    @usage Example:

        local logging = require("logging")
        local logger  = logging.Logger.new(shell.getRunningProgram())

        logger:info("This message will be logged")
]]
local Logger = {}

--- Create's a new Logger instance.
-- @tparam string name The logger name.
-- @tparam number level The level weight.
-- @tparam Formatter formatter The formatter to use.
-- @treturn Logger instance
function Logger.new(name, level, formatter)
    local instance     = setmetatable({}, { __index = Logger })
    instance.name      = name
    instance.level     = level or 0
    instance.formatter = formatter or Formatter.new()
    instance.levels    = {
        ["DEBUG"]    = Level.new("DEBUG", 10, colors.cyan),
        ["INFO"]     = Level.new("INFO", 20, colors.green),
        ["WARN"]     = Level.new("WARN", 30, colors.yellow),
        ["ERROR"]    = Level.new("ERROR", 40, colors.red),
        ["CRITICAL"] = Level.new("CRITICAL", 50, colors.magenta),
    }
    instance.handlers  = {
        TerminalHandler.new(instance.formatter),
    }
    return instance
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

--- Adds a new handler to the logger.
-- @tparam table handler The handler to add.
function Logger:addHandler(handler)
    table.insert(self.handlers, handler)
end

function Logger:registerLevel(level)
    self.levels[level.name] = level
end

--- logs a message
-- @tparam Level level the level of the message
-- @tparam string ... The arguments to log
function Logger:log(level, ...)
    local msg    = tableConcatForamt(...)
    local record = Record.new(level, msg, self.name)

    for i = 1, #self.handlers, 1 do
        self.handlers[i]:handle(record)
    end

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

return logging
