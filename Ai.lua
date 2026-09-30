-- KioAi | Universal Script Connected to Gemini
-- This Script Is Made By Cyber/ Germilns
-- Anyone can !Ask when it is running

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PREFIX_ASK = "!Ask"
local PREFIX_START = "!Start"
local PREFIX_STOP = "!Stop"
local AI_NAME = "KioAi"

-- ========== CONFIG ==========
local GEMINI_API_KEY = "AQ.Ab8RN6JyrOYhGDjDm_vMBIfU4golNgiRLA1YZ_5DNzVNttJm5A"
local MODEL = "gemini-1.5-flash"
-- ============================

local enabled = false

local function getRequest()
    return (syn and syn.request) or (http and http.request) or http_request or request
end

local function sendChat(message)
    pcall(function()
        local channel = TextChatService.TextChannels.RBXGeneral
        if channel then
            channel:SendAsync(message)
            return
        end
    end)

    pcall(function()
        local say = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
        if say and say:FindFirstChild("SayMessageRequest") then
            say.SayMessageRequest:FireServer(message, "All")
        end
    end)
end

local function askGemini(prompt)
    local req = getRequest()
    if not req then
        return "Executor does not support HTTP requests."
    end

    local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. MODEL .. ":generateContent?key=" .. GEMINI_API_KEY

    local body = HttpService:JSONEncode({
        contents = {
            {
                parts = {
                    {text = "You are KioAi, a helpful, fun and slightly playful AI assistant inside a Roblox game. Keep answers short and chat-friendly (under 150 characters). Always stay in character as KioAi.\n\nUser: " .. prompt}
                }
            }
        },
        generationConfig = {
            maxOutputTokens = 120,
            temperature = 0.7
        }
    })

    local success, response = pcall(function()
        return req({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = body
        })
    end)

    if not success or not response or response.StatusCode \~= 200 then
        return "KioAi is busy right now, try again later."
    end

    local data = HttpService:JSONDecode(response.Body)
    if data.candidates and data.candidates[1] and data.candidates[1].content and data.candidates[1].content.parts then
        return data.candidates[1].content.parts[1].text
    end

    return "Couldn't get a response from KioAi."
end

local function onMessage(message, player)
    if not message or type(message) \~= "string" then return end

    local lower = message:lower()
    local isLocal = player == LocalPlayer

    if isLocal then
        if lower == PREFIX_START:lower() or lower:match("^" .. PREFIX_START:lower() .. "%s*$") then
            enabled = true
            sendChat(AI_NAME .. ": Online! Type !Ask <question>")
            return
        elseif lower == PREFIX_STOP:lower() or lower:match("^" .. PREFIX_STOP:lower() .. "%s*$") then
            enabled = false
            sendChat(AI_NAME .. ": Offline.")
            return
        end
    end

    if not enabled then return end
    if not lower:match("^" .. PREFIX_ASK:lower()) then return end

    local question = message:sub(#PREFIX_ASK + 1):match("^%s*(.-)%s*$")
    if not question or question == "" then
        sendChat(AI_NAME .. ": Ask me something! Example: !Ask What is Roblox?")
        return
    end

    task.spawn(function()
        local reply = askGemini(question)
        reply = reply:gsub("\n", " "):gsub("%s+", " "):sub(1, 180)
        sendChat(AI_NAME .. ": " .. reply)
    end)
end

-- Modern TextChatService
pcall(function()
    TextChatService.MessageReceived:Connect(function(textChatMessage)
        if textChatMessage.TextSource then
            onMessage(textChatMessage.Text, Players:GetPlayerByUserId(textChatMessage.TextSource.UserId))
        end
    end)
end)

-- Legacy chat
pcall(function()
    local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
    if chatEvents then
        local onMessageDone = chatEvents:FindFirstChild("OnMessageDoneFiltering")
        if onMessageDone then
            onMessageDone.OnClientEvent:Connect(function(data)
                if data and data.Message and data.FromSpeaker then
                    onMessage(data.Message, Players:FindFirstChild(data.FromSpeaker))
                end
            end)
        end
    end
end)

LocalPlayer.Chatted:Connect(function(msg)
    onMessage(msg, LocalPlayer)
end)

-- Announce when script is executed
task.wait(0.5)
sendChat("KioAi On Say !Ask <Question>")

print("KioAi loaded (Gemini)")
print("Commands (only you): !Start  |  !Stop")
print("Anyone can use: !Ask <question>  (after you !Start)")
