local ADDON_NAME = ...

local SUPPRESSION_SECONDS = 10
local LEVEL_UP_TEXT = "ding"

-- Each trigger has its own suppression window per chat type. "replyToSelf"
-- lets the ding trigger congratulate your own level-up announcement; this
-- cannot loop because "grats" does not contain the word "ding".
local TRIGGERS = {
    {
        key = "yeahright",
        pattern = "%syeah%s*right%s",
        response = "yeah right",
        replyToSelf = false,
    },
    {
        key = "ding",
        pattern = "%sding%s",
        response = "grats",
        replyToSelf = true,
    },
}

local EVENT_TO_CHAT_TYPE = {
    CHAT_MSG_GUILD = "GUILD",
    CHAT_MSG_PARTY = "PARTY",
    CHAT_MSG_PARTY_LEADER = "PARTY",
    CHAT_MSG_RAID = "RAID",
    CHAT_MSG_RAID_LEADER = "RAID",
    CHAT_MSG_SAY = "SAY",
    CHAT_MSG_YELL = "YELL",
}

local suppressionUntil = {}
local playerGUID

local function Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Yeah Right|r: " .. message)
end

local function IsSecret(value)
    return type(issecretvalue) == "function" and issecretvalue(value)
end

local function Debug(message)
    if YeahRightDB and YeahRightDB.debug then
        Print("|cffaaaaaa[debug]|r " .. message)
    end
end

local function PrintHelp()
    Print("Commands:")
    Print("  /yeahright on - enable automatic replies")
    Print("  /yeahright off - disable automatic replies")
    Print("  /yeahright status - show the current status")
    Print("  /yeahright debug - toggle diagnostic messages")
    Print("  /yeahright help - show this command list")
end

local function NormalizeMessage(message)
    -- Convert punctuation and repeated spacing into a single searchable form.
    -- This matches examples such as "Yeah Right", "yeah... right!", and the
    -- joined form "yeahright", while avoiding longer words like "yeahrightly".
    local normalized = string.lower(message)
    normalized = string.gsub(normalized, "[^%w]+", " ")
    return " " .. normalized .. " "
end

local function IsOwnMessage(sender, senderGUID)
    playerGUID = playerGUID or UnitGUID("player")

    if not IsSecret(senderGUID) and senderGUID ~= nil and senderGUID ~= "" then
        return senderGUID == playerGUID
    end

    -- GUID is normally available. Keep a name fallback for beta builds or chat
    -- types that omit it, without attempting to inspect protected values.
    if not IsSecret(sender) and type(sender) == "string" then
        local playerName = UnitName("player")
        local senderName = string.match(sender, "^([^-]+)")
        return senderName == playerName
    end

    return false
end

local function CanAttemptSend(chatType)
    -- SAY and YELL require a hardware event outdoors. Do not deliberately call
    -- a protected API where the client is already known to reject it.
    if chatType == "SAY" or chatType == "YELL" then
        local inInstance = IsInInstance()
        if not inInstance then
            return false, "SAY/YELL automatic sends require an instance"
        end
    end

    return true
end

local function AttemptSend(text, chatType)
    local canSend, reason = CanAttemptSend(chatType)
    if not canSend then
        Debug("skipped " .. chatType .. ": " .. reason)
        return
    end

    local sendFunction = C_ChatInfo and C_ChatInfo.SendChatMessage
    if type(sendFunction) ~= "function" then
        Debug("skipped " .. chatType .. ": C_ChatInfo.SendChatMessage is unavailable")
        return
    end

    -- A secure call prevents taint from propagating into Blizzard's chat API.
    -- The client may still refuse the send in a protected encounter; messages
    -- are intentionally not queued for later delivery.
    if type(securecallfunction) == "function" then
        securecallfunction(sendFunction, text, chatType)
    else
        sendFunction(text, chatType)
    end

    Debug("attempted \"" .. text .. "\" in " .. chatType)
end

local function HandleChatEvent(event, message, sender, languageName, channelName,
    target, flags, zoneChannelID, channelIndex, channelBaseName, unused,
    lineID, senderGUID)

    if not YeahRightDB or not YeahRightDB.enabled then
        return
    end

    local chatType = EVENT_TO_CHAT_TYPE[event]
    if not chatType then
        return
    end

    if IsSecret(message) then
        Debug("skipped protected " .. chatType .. " message")
        return
    end

    if type(message) ~= "string" then
        return
    end

    local normalized = NormalizeMessage(message)
    local isOwn = IsOwnMessage(sender, senderGUID)
    local now = GetTime()

    for _, trigger in ipairs(TRIGGERS) do
        if string.find(normalized, trigger.pattern) then
            local suppressionKey = trigger.key .. ":" .. chatType

            if now < (suppressionUntil[suppressionKey] or 0) then
                Debug("suppressed repeat " .. trigger.key .. " in " .. chatType)
            else
                -- Start suppression before attempting a reply. This prevents
                -- simultaneous addon responses from creating a feedback loop.
                suppressionUntil[suppressionKey] = now + SUPPRESSION_SECONDS

                if isOwn and not trigger.replyToSelf then
                    Debug("recorded your own " .. trigger.key .. " in " .. chatType .. "; no reply sent")
                else
                    Debug("detected " .. trigger.key .. " in " .. chatType)
                    AttemptSend(trigger.response, chatType)
                end
            end
        end
    end
end

local function AnnounceLevelUp()
    if not YeahRightDB or not YeahRightDB.enabled then
        return
    end

    if IsInGuild() then
        AttemptSend(LEVEL_UP_TEXT, "GUILD")
    end

    if IsInRaid() then
        AttemptSend(LEVEL_UP_TEXT, "RAID")
    elseif IsInGroup() then
        AttemptSend(LEVEL_UP_TEXT, "PARTY")
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LEVEL_UP")

for event in pairs(EVENT_TO_CHAT_TYPE) do
    frame:RegisterEvent(event)
end

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon ~= ADDON_NAME then
            return
        end

        YeahRightDB = YeahRightDB or {}
        if YeahRightDB.enabled == nil then
            YeahRightDB.enabled = true
        end
        if YeahRightDB.debug == nil then
            YeahRightDB.debug = false
        end

        playerGUID = UnitGUID("player")
        self:UnregisterEvent("ADDON_LOADED")
        Debug("loaded; replies are " .. (YeahRightDB.enabled and "enabled" or "disabled"))
        return
    end

    if event == "PLAYER_LEVEL_UP" then
        AnnounceLevelUp()
        return
    end

    HandleChatEvent(event, ...)
end)

SLASH_YEAHRIGHT1 = "/yeahright"
SlashCmdList.YEAHRIGHT = function(input)
    local command = string.lower((input or ""):match("^%s*(.-)%s*$"))

    if command == "on" then
        YeahRightDB.enabled = true
        Print("enabled")
    elseif command == "off" then
        YeahRightDB.enabled = false
        Print("disabled")
    elseif command == "status" then
        Print("replies are " .. (YeahRightDB.enabled and "enabled" or "disabled")
            .. "; debug is " .. (YeahRightDB.debug and "enabled" or "disabled")
            .. "; suppression window is " .. SUPPRESSION_SECONDS .. " seconds")
    elseif command == "debug" then
        YeahRightDB.debug = not YeahRightDB.debug
        Print("debug " .. (YeahRightDB.debug and "enabled" or "disabled"))
    elseif command == "" or command == "help" then
        PrintHelp()
    else
        Print("unknown command: " .. command)
        PrintHelp()
    end
end
