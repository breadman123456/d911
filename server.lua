--- Config ---
webhookURL = ''
prefix = '^1[911] ^7';
roleList = {
    "SAST",
    "BCSO",
    "LSPD",
    "USBP",
    "SAFR",
}

--- Code ---
function sendMsg(src, msg)
    TriggerClientEvent('chat:addMessage', src, {
        args = { prefix .. msg }
    })
end

function sendToDisc(title, message, footer)
    local embed = {}
    embed = {
        {
            ["color"] = 16711680, -- GREEN = 65280 --- RED = 16711680
            ["title"] = "**".. title .."**",
            ["description"] = "" .. message ..  "",
            ["footer"] = {
                ["text"] = footer,
            },
        }
    }
    PerformHttpRequest(webhookURL, 
    function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
end

isCop = {}
AddEventHandler('playerDropped', function(reason) 
  local src = source;
  isCop[src] = nil;
end)

RegisterNetEvent('d911:check-permissions')
AddEventHandler('d911:check-permissions', function()
    local src = source;
    for k, v in ipairs(GetPlayerIdentifiers(src)) do
        if string.sub(v, 1, string.len("discord:")) == "discord:" then
            identifierDiscord = v
        end
    end

if identifierDiscord then
    local roleIDs = exports.Badger_Discord_API:GetDiscordRoles(src)
    if not (roleIDs == false) then
        for i = 1, #roleList do
            for j = 1, #roleIDs do
                if exports.Badger_Discord_API:CheckEqual(roleList[i], roleIDs[j]) then
                    isCop[tonumber(src)] = true;
                    print("[d911] " .. GetPlayerName(src) .. " has received permissions to view emergency calls.")
                end
            end
        end
    else
        print("[d911] " .. GetPlayerName(src) .. " did not receive permissions to view emergency calls.")
    end
elseif identifierDiscord == nil then
    print("identifierDiscord == nil")
end
end)

locationTracker = {}
idCounter = 0;
function mod(a, b)
    return a - (math.floor(a/b)*b)
end

RegisterCommand("resp", function(source, args, raw)
    if (#args > 0) then 
        if tonumber(args[1]) ~= nil then 
            if locationTracker[tonumber(args[1])] ~= nil then 
                -- It is valid, set their waypoint 
                local loc = locationTracker[tonumber(args[1])]
                TriggerClientEvent("d911:set-waypoint", source, loc[1], loc[2]);
                sendMsg(source, "Your waypoint has been set to the situation!")
            else 
                -- Not valid 
                sendMsg(source, "^1That is not a valid situation.")
            end
        else 
            -- Not a valid number 
            sendMsg(source, "^1That is not a valid number you supplied.")
        end
    end
end)
RegisterCommand("911", function(s
           ource, args, raw)
    -- 11 command 
    local x, y, z = table.unpack(GetEntityCoords(GetPlayerPed(source)));
    if (#args > 0) then 
        idCounter = idCounter + 1;
        locationTracker[idCounter] = {x, y};
        if mod(idCounter, 12) == 0 then 
            -- Is a multiple of 12 with no remainder, we can remove 6 of the last 
            local cout = idCounter - 12;
            while cout < (idCounter - 6) do 
                locationTracker[cout] = nil;
                cout = cout + 1;
            end
            idCounter = 1;
            locationTracker[idCounter] = {x, y};
        end
        sendMsg(source, "Your 911 call has been received! The authorities are on their way!");
        sendToDisc("[RESPONSE CODE: " .. idCounter .. "] " ..
         "INCOMING TRANSMISSION:", table.concat(args, " "), "[" .. source .. "] " .. GetPlayerName(source))
        for _, id in ipairs(GetPlayers()) do 
            if isCop[tonumber(id)] ~= nil and isCop[tonumber(id)] == true then 
                -- They are a cop, send them it 
                sendMsg(id, "[^7Use ^2/resp " .. idCounter .. "^7 to respond^3] " .. "^1INCOMING TRANSMISSION: ^3" .. table.concat(args, " "));
            end
        end
    end
end)
