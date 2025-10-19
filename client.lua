local Client = {}
Client.__index = Client

function Client:new(token, options)
    options = options or {}
    local self = setmetatable({}, Client)
    
    -- Security: Validate token format
    if not token or token == "" then
        error("Bot token is required")
    end
    if token:match("Bot%s+%w+%.%w+%.%w+") == nil then
        error("Invalid bot token format")
    end
    
    self.token = token
    self.gateway = "wss://gateway.discord.gg/?v=10&encoding=json"
    
    -- Initialize systems
    self.cache = require("luacord.cache").createLRU(options.cache_max_size, options.cache_ttl)
    self.rate_limiter = require("luacord.ratelimiter").createBucketManager()
    self.http = require("luacord.utils.http_client"):new(self)
    self.async_handler = require("luacord.async").createHandler()
    
    -- Async WebSocket support
    self.use_async_websocket = options.use_async_websocket or false
    self.ws = nil
    
    -- Concurrency mode
    self.concurrency_mode = options.concurrency_mode or "sync" -- "sync", "async", "coroutine"
    
    -- Event system
    self.event_emitter = require("luacord.events").createEmitter()
    
    -- Command system
    self.commands = require("luacord.commands").createSystem(self)
    
    -- Logging
    self.logger = options.logger or require("luacord.logging").create(require("luacord.logging").LEVELS.INFO)
    
    -- Security: Don't log full token
    local safe_token = token:sub(1, 10) .. "..."
    self.logger:info("CLIENT", "Luacord client initialized (token: %s)", safe_token)
    
    return self
end

-- Async connect method
function Client:connect_async()
    if self.use_async_websocket then
        local AsyncWebSocket = require("luacord.gateway.async_websocket")
        self.ws = AsyncWebSocket:new(self.gateway, {
            max_reconnect_attempts = self.max_reconnect_attempts
        })
        
        self.ws:on("on_message", function(message)
            self:handle_gateway_message(message)
        end)
        
        self.ws:on("on_error", function(err)
            self.logger:error("GATEWAY", "WebSocket error: %s", err)
        end)
        
        local co = self.ws:connect_async()
        self.async_handler:queue_coroutine(co)
        
    else
        -- Fallback to synchronous connection
        self:connect()
    end
end

-- Coroutine-friendly HTTP methods
function Client:request_async(method, endpoint, data)
    return coroutine.create(function()
        local result, err = self.http:request(method, endpoint, data)
        if not result then
            error(err)
        end
        coroutine.yield(result)
    end)
end

function Client:send_message_async(channel_id, content, options)
    return self:request_async("POST", "/channels/" .. channel_id .. "/messages", {
        content = content,
        tts = options and options.tts,
        embeds = options and options.embeds
    })
end

-- Main run method with concurrency support
function Client:run()
    if self.concurrency_mode == "async" then
        self:run_async()
    elseif self.concurrency_mode == "coroutine" then
        self:run_coroutine()
    else
        self:run_sync()
    end
end

function Client:run_async()
    self.logger:info("CLIENT", "Starting in async mode")
    self.async_handler:run()
end

function Client:run_coroutine()
    self.logger:info("CLIENT", "Starting in coroutine mode")
    
    -- Start gateway in coroutine
    local gateway_co = coroutine.create(function()
        self:connect()
        self:gateway_loop()
    end)
    
    -- Start HTTP processing in another coroutine
    local http_co = coroutine.create(function()
        while true do
            self:process_http_queue()
            coroutine.yield()
        end
    end)
    
    -- Simple coroutine scheduler
    while true do
        local co_status = coroutine.status(gateway_co)
        if co_status ~= "dead" then
            local ok, err = coroutine.resume(gateway_co)
            if not ok then
                self.logger:error("COROUTINE", "Gateway coroutine error: %s", err)
            end
        end
        
        local ok, err = coroutine.resume(http_co)
        if not ok then
            self.logger:error("COROUTINE", "HTTP coroutine error: %s", err)
        end
        
        -- Small sleep to prevent busy waiting
        self.http:async_sleep(0.01)
    end
end

function Client:run_sync()
    self.logger:info("CLIENT", "Starting in synchronous mode")
    self:connect()
    
    while true do
        local msg = self.ws:receive(1)
        if msg then
            self:handle_gateway_message(msg)
        end
        
        -- Process heartbeats and other sync tasks
        self:process_tasks()
    end
end