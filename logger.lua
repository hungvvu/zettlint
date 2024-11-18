local Logger = {}

local levels = {
    DEBUG = 1,
    INFO = 2,
    WARN = 3,
    ERROR = 4
}

-- Set the current log level (default INFO)
Logger.current_level = levels.DEBUG

function Logger.set_level(level)
    Logger.current_level = levels[level] or levels.INFO
end

function Logger.debug(msg)
    if Logger.current_level <= levels.DEBUG then
        print("[DEBUG] " .. msg)
    end
end

function Logger.info(msg)
    if Logger.current_level <= levels.INFO then
        print("[INFO] " .. msg)
    end
end

function Logger.warn(msg)
    if Logger.current_level <= levels.WARN then
        print("[WARN] " .. msg)
    end
end

function Logger.error(msg)
    if Logger.current_level <= levels.ERROR then
        print("[ERROR] " .. msg)
    end
end

return Logger

