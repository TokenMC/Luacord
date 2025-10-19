local Client = require("luacord.client")
local Utils = require("luacord.utils")
local Logging = require("luacord.logging")
local CommandSystem = require("luacord.command_system")
local EventBatcher = require("luacord.event_batcher")
local AsyncHandler = require("luacord.async_handler")

return {
    -- Core
    Client = Client,
    
    -- Modular systems
    Utils = Utils,
    Logging = Logging,
    CommandSystem = CommandSystem,
    EventBatcher = EventBatcher,
    AsyncHandler = AsyncHandler,
    
    -- Convenience exports
    calculateIntents = Client.calculateIntents,
    createEmbed = Utils.createEmbed,
    createButton = Utils.createButton,
    createActionRow = Utils.createActionRow,
    createSelectMenu = Utils.createSelectMenu,
    calculatePermissions = Utils.calculatePermissions,
    
    -- Logging levels
    LOG_DEBUG = Logging.DEBUG,
    LOG_INFO = Logging.INFO,
    LOG_WARN = Logging.WARN,
    LOG_ERROR = Logging.ERROR
}