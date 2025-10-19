# Luacord – Experimental Discord API Wrapper for Pure Lua

[![Lua](https://img.shields.io/badge/Lua-Blue?logo=lua&logoColor=white)](https://www.lua.org/)  
[![Discord](https://img.shields.io/badge/Discord-7289DA?logo=discord&logoColor=white)](https://discord.com/)  
[![License](https://img.shields.io/badge/License-Unlicense-green)](LICENSCE)

---

## Description

**Luacord** is an experimental Discord API wrapper written entirely in Lua.  
It allows you to build Discord bots quickly and efficiently with **minimal external dependencies**, supporting asynchronous operations and a modular **cog system** for scalable command management.

---

## Features

- Fully written in Lua (pure, minimal external dependencies)  
- Beginner-friendly and simple interface  
- Supports asynchronous bot operations  
- Cog system for modular commands  
- Lightweight and efficient
- Activeky Developed

---

## Installation

1. Clone the repository:

```bash
git clone https://github.com/Tokenmc/luacord.git
cd luacord

2. Install Lua if not already installed: https://www.lua.org/download.html


3. (Optional) Install dependencies if required for advanced features.
```

---

## Simple Bot Example
```
local luacord = require("luacord")

local bot = luacord.Client:new("YOUR_BOT_TOKEN")

-- Triggered when the bot is ready
bot:on("ready", function()
    print("Logged in as " .. bot.user.username)
end)

-- Respond to messages
bot:on("messageCreate", function(message)
    if message.content == "!ping" then
        message.channel:send("Pong!")
    end
end)

-- Run the bot
bot:run()
```
Quick Start

Basic Bot Example

```lua
local luacord = require("luacord")

-- Create bot client
local client = luacord.createClient("YOUR_BOT_TOKEN")

-- Event: Bot is ready
client:on("READY", function(data)
    print("🚀 Bot is ready! Logged in as: " .. data.user.username)
end)

-- Event: Message handler
client:on("MESSAGE_CREATE", function(message)
    if message.content == "!ping" then
        client:sendMessage(message.channel_id, "🏓 Pong!")
    end
end)

-- Start the bot
client:connect()
client:run()
```

Advanced Bot with Slash Commands

```lua
local luacord = require("luacord")

local client = luacord.createClient("YOUR_BOT_TOKEN", {
    intents = luacord.calculateIntents("guilds", "guild_messages", "message_content")
})

client:on("READY", function()
    print("✅ Bot is online!")
end)

-- Register slash command
client:registerCommand("ping", "Check bot latency", function(client, interaction)
    client:replyToInteraction(interaction.id, interaction.token, {
        type = 4,
        data = {
            content = "🏓 Pong!",
            flags = 64  -- Ephemeral message
        }
    })
end)

-- Register command with options
client:registerCommand("userinfo", "Get user information", {
    {
        name = "user",
        description = "User to get info about",
        type = 6,  -- USER type
        required = false
    }
}, function(client, interaction)
    local user_id = interaction.data.options and interaction.data.options[1] and 
                   interaction.data.options[1].value or interaction.member.user.id
    local user = interaction.data.resolved.users[user_id]
    
    local embed = luacord.createEmbed()
        :setTitle("👤 User Information")
        :addField("Username", user.username, true)
        :addField("ID", user.id, true)
        :setColor(0x0099ff)
    
    client:replyToInteraction(interaction.id, interaction.token, {
        type = 4,
        data = { embeds = { embed } }
    })
end)

client:connect()
client:run()
```

---

🧩 Cog System Example

Creating a Cog

```lua
-- cogs/moderation.lua
local Moderation = {}
Moderation.__index = Moderation

function Moderation:setup(client)
    self.client = client
    
    -- Register moderation commands
    client:registerCommand("ban", "Ban a user", {
        {
            name = "user",
            description = "User to ban",
            type = 6,
            required = true
        },
        {
            name = "reason",
            description = "Reason for ban",
            type = 3,
            required = false
        }
    }, function(client, interaction)
        local user_id = interaction.data.options[1].value
        local reason = interaction.data.options[2] and interaction.data.options[2].value or "No reason provided"
        
        local embed = luacord.createEmbed()
            :setTitle("🔨 User Banned")
            :addField("User", "<@" .. user_id .. ">", true)
            :addField("Reason", reason, true)
            :setColor(0xff0000)
        
        client:replyToInteraction(interaction.id, interaction.token, {
            type = 4,
            data = { embeds = { embed } }
        })
    end, "moderation")
    
    print("✅ Moderation cog loaded")
end

return Moderation
```

Using Cogs

```lua
local client = luacord.createClient("YOUR_BOT_TOKEN")

-- Load cogs
client.cog_manager:loadCog("moderation")
client.cog_manager:loadCog("utility")

client:connect()
client:run()
```

---

⚡ Advanced Features

Buttons and Interactions

```lua
client:registerCommand("buttons", "Show example buttons", function(client, interaction)
    local action_row = luacord.createActionRow()
    local button1 = luacord.createButton(1, "Primary", "btn_primary")
    local button2 = luacord.createButton(2, "Secondary", "btn_secondary")
    local button3 = luacord.createButton(4, "Danger", "btn_danger")
    
    action_row.components = {button1, button2, button3}
    
    client:replyToInteraction(interaction.id, interaction.token, {
        type = 4,
        data = {
            content = "Here are some buttons:",
            components = {action_row}
        }
    })
end)

-- Handle button clicks
client:on("INTERACTION_CREATE", function(interaction)
    if interaction.type == 3 then  -- Message component
        local custom_id = interaction.data.custom_id
        
        if custom_id == "btn_primary" then
            client:replyToInteraction(interaction.id, interaction.token, {
                type = 7,  -- Update message
                data = { content = "You clicked Primary! ✅" }
            })
        end
    end
end)
```

Async Operations

```lua
-- Coroutine-based async HTTP
local co = client:request_async("GET", "/users/@me")
local user_data = coroutine.resume(co)

-- Promise-based operations
local promise = luacord.Promise:new(function(resolve, reject)
    -- Simulate async operation
    client.async_handler:set_timeout(function()
        resolve("Operation completed!")
    end, 2)
end)

promise:then_(function(result)
    print("Success:", result)
end):catch(function(error)
    print("Error:", error)
end)
```

Advanced Configuration

```lua
local client = luacord.createClient("YOUR_BOT_TOKEN", {
    intents = luacord.calculateIntents(
        "guilds", "guild_messages", "message_content",
        "guild_members", "guild_message_reactions"
    ),
    presence = {
        status = "online",
        activities = {{
            name = "Luacord Bot",
            type = 0,  -- Playing
            state = "With Lua Code"
        }}
    },
    cache = {
        ttl = 300,      -- 5 minutes
        max_size = 1000 -- Maximum cache items
    },
    logging = {
        level = "INFO",
        colors = true
    },
    use_async_websocket = true,
    auto_reconnect = true
})
```

---

📚 API Reference

Core Methods

```lua
-- Client creation
local client = luacord.createClient(token, options)

-- Event handling
client:on("READY", callback)
client:on("MESSAGE_CREATE", callback)
client:on("INTERACTION_CREATE", callback)

-- Message operations
client:sendMessage(channel_id, content, options)
client:editMessage(channel_id, message_id, content)
client:deleteMessage(channel_id, message_id)

-- Slash commands
client:registerCommand(name, description, options, callback, namespace)

-- Interactions
client:replyToInteraction(interaction_id, token, response_data)
```

Utility Functions

```lua
-- Embed builder
local embed = luacord.createEmbed()
    :setTitle("Title")
    :setDescription("Description")
    :addField("Name", "Value", true)
    :setColor(0x0099ff)
    :setTimestamp()

-- Markdown formatting
local bold = luacord.bold("text")
local italic = luacord.italic("text")
local code = luacord.code("print('hello')")

-- Snowflake utilities
local snowflake_data = luacord.parseSnowflake("123456789012345678")
print("Created:", snowflake_data.datetime)
```

---

🏗️ Project Structure

```
luacord/
├── lua/luacord/
│   ├── client.lua              # Main client class
│   ├── gateway/                # WebSocket connection
│   ├── commands/               # Slash command system
│   ├── cache/                  # Caching system
│   ├── ratelimiter/            # Rate limit handling
│   ├── async/                  # Async operations
│   ├── utils/                  # Utility functions
│   ├── cogs/                   # Modular cog system
│   └── plugins/                # Plugin system
├── examples/                   # Example bots
│   ├── simple_bot.lua
│   ├── advanced_bot.lua
│   └── cog_example.lua
└── docs/                       # Documentation
    ├── GETTING_STARTED.md
    ├── API.md
    └── COGS.md
```

---

🛠️ Configuration

Environment Variables

```bash
# .env file
DISCORD_TOKEN=your_bot_token_here
LUACORD_TOKEN=your_bot_token_here
LOG_LEVEL=INFO
```

Config File

```json
{
    "token": "YOUR_BOT_TOKEN",
    "intents": ["guilds", "guild_messages", "message_content"],
    "presence": {
        "status": "online",
        "activities": [{
            "name": "Luacord Bot",
            "type": 0
        }]
    },
    "cogs": ["utility", "moderation"],
    "plugins": ["metrics"]
}
```

---

🤝 Contributing

We welcome contributions! Here's how you can help:

1. Fork the repository
2. Create a feature branch (git checkout -b feature/amazing-feature)
3. Commit your changes (git commit -m 'Add amazing feature')
4. Push to the branch (git push origin feature/amazing-feature)
5. Open a Pull Request

Development Setup

```bash
git clone https://github.com/Tokenmc/luacord.git
cd luacord
# Start coding!
```

---

📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

⚠️ Disclaimer

Luacord is an experimental project and is not officially affiliated with Discord Inc. Use at your own risk in production environments.

---

🆘 Support

· 📚 Documentation: Check the /docs folder
· 🐛 Issues: Report bugs on GitHub Issues
· 💡 Examples: See the /examples folder for code samples
· ❓ Questions: Open a discussion on GitHub

---

🎉 Acknowledgments

· Discord for their excellent API documentation
· Lua community for the wonderful programming language
· Contributors who help improve Luacord

---

⭐ If you find Luacord useful, please consider giving it a star on GitHub!

---

Created with 💙 by ItzNuclear
---

```
