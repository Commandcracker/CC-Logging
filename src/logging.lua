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
        local level   = logging.Level.new("My Logger", nil, colours.orange, colours.blue)

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
    instance.textcolor       = textcolor or colours.white
    instance.backgroundcolor = backgroundcolor or colours.black
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
    temp = self.fmt
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

local function convertTrueColor(color)
    --[[
        24-bit/true Colors
        https://en.wikipedia.org/wiki/ANSI_escape_code#24-bit
    ]]

    local r, g, b

    if color == colours.white then
        r, g, b = 240, 240, 240
    elseif color == colours.orange then
        r, g, b = 242, 178, 51
    elseif color == colours.magenta then
        r, g, b = 229, 127, 216
    elseif color == colours.lightBlue then
        r, g, b = 153, 178, 242
    elseif color == colours.yellow then
        r, g, b = 222, 222, 108
    elseif color == colours.lime then
        r, g, b = 127, 204, 25
    elseif color == colours.pink then
        r, g, b = 242, 178, 204
    elseif color == colours.grey then
        r, g, b = 76, 76, 76
    elseif color == colours.lightGrey then
        r, g, b = 153, 153, 153
    elseif color == colours.cyan then
        r, g, b = 76, 153, 178
    elseif color == colours.purple then
        r, g, b = 178, 102, 229
    elseif color == colours.blue then
        r, g, b = 51, 102, 204
    elseif color == colours.brown then
        r, g, b = 127, 102, 76
    elseif color == colours.green then
        r, g, b = 87, 166, 78
    elseif color == colours.red then
        r, g, b = 204, 76, 76
    elseif color == colours.black then
        r, g, b = 17, 17, 17
    end

    return r, g, b
end

local function convertForgroundColor(color)
    --[[
        3-bit and 4-bit Colors
        https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
        Note: Some colors like pink and purple need to share the same color code.
        Note: Colors are not acurate, they vary on your os and terminal settings.
    ]]

    local code

    if color == colours.white then
        code = 97
    elseif color == colours.orange then
        code = 33
    elseif color == colours.magenta then
        code = 95
    elseif color == colours.lightBlue then
        code = 94
    elseif color == colours.yellow then
        code = 93
    elseif color == colours.lime then
        code = 92
    elseif color == colours.pink then
        code = 35
    elseif color == colours.grey then
        code = 37
    elseif color == colours.lightGrey then
        code = 90
    elseif color == colours.cyan then
        code = 36
    elseif color == colours.purple then
        code = 35
    elseif color == colours.blue then
        code = 34
    elseif color == colours.brown then
        code = 93
    elseif color == colours.green then
        code = 32
    elseif color == colours.red then
        code = 31
    elseif color == colours.black then
        code = 30
    end

    return code
end

local function convertBackgroundColor(color)
    --[[
        3-bit and 4-bit Colors
        https://en.wikipedia.org/wiki/ANSI_escape_code#3-bit_and_4-bit
        Note: Some colors like pink and purple need to share the same color code.
        Note: Colors are not acurate, they vary on your os and terminal settings.
    ]]
    local code

    if color == colours.white then
        code = 107
    elseif color == colours.orange then
        code = 43
    elseif color == colours.magenta then
        code = 105
    elseif color == colours.lightBlue then
        code = 104
    elseif color == colours.yellow then
        code = 103
    elseif color == colours.lime then
        code = 102
    elseif color == colours.pink then
        code = 45
    elseif color == colours.grey then
        code = 47
    elseif color == colours.lightGrey then
        code = 100
    elseif color == colours.cyan then
        code = 46
    elseif color == colours.purple then
        code = 45
    elseif color == colours.blue then
        code = 44
    elseif color == colours.brown then
        code = 103
    elseif color == colours.green then
        code = 42
    elseif color == colours.red then
        code = 41
    elseif color == colours.black then
        code = 40
    end

    return code
end

--[[- Will send the formatted record message with [ansi escape codes (for the color)](https://en.wikipedia.org/wiki/ANSI_escape_code#Colors) to a websocket.
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
    --local ForgroundColor  = convertForgroundColor(record.level.textcolor)
    --local BackgroundColor = convertBackgroundColor(record.level.backgroundcolor)

    local fr, fg, fb = convertTrueColor(record.level.textcolor)
    local br, bg, bb = convertTrueColor(record.level.backgroundcolor)

    local ForgroundColor  = "38;2;" .. fr .. ";" .. fg .. ";" .. fb
    local BackgroundColor = "48;2;" .. br .. ";" .. bg .. ";" .. bb

    self.websocket.send(
        "\x1b[" .. ForgroundColor .. "m" ..
        "\x1b[" .. BackgroundColor .. "m" ..
        self.formatter:format(record) ..
        "\x1b[39m" ..
        "\x1b[49m"
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
    local old_text_colour = term.getTextColor()
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
        ["DEBUG"]    = Level.new("DEBUG", 10, colours.cyan),
        ["INFO"]     = Level.new("INFO", 20, colours.green),
        ["WARN"]     = Level.new("WARN", 30, colours.yellow),
        ["ERROR"]    = Level.new("ERROR", 40, colours.red),
        ["CRITICAL"] = Level.new("CRITICAL", 50, colours.magenta),
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
