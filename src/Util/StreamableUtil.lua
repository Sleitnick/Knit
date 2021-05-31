-- StreamableUtil
-- Stephen Leitnick
-- March 03, 2021

--[[

	StreamableUtil.Compound(observers: {Observer}, handler: ({[child: string]: Instance}, maid: Maid) -> void): Maid

	Example:

		local streamable1 = Streamable.new(someModel, "SomeChild")
		local streamable2 = Streamable.new(anotherModel, "AnotherChild")

		StreamableUtil.Compound({S1 = streamable1, S2 = streamable2}, function(streamables, maid)
			local someChild = streamables.S1.Instance
			local anotherChild = streamables.S2.Instance
			maid:GiveTask(function()
				-- Cleanup
			end)
		end)

--]]


local Maid = require(script.Parent.Maid)
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local StreamableUtil = {}

function StreamableUtil.Compound(streamables, handler)
	local compoundMaid = Maid.new()
	local observeAllMaid = Maid.new()
	local allAvailable = false
	local function Check()
		if allAvailable then return end
		for _,streamable in pairs(streamables) do
			if not streamable.Instance then
				return
			end
		end
		allAvailable = true
		handler(streamables, observeAllMaid)
	end
	local function Cleanup()
		if not allAvailable then return end
		allAvailable = false
		observeAllMaid:DoCleaning()
	end
	for _,streamable in pairs(streamables) do
		compoundMaid:GiveTask(streamable:Observe(function(_child, maid)
			Check()
			maid:GiveTask(Cleanup)
		end))
	end
	compoundMaid:GiveTask(Cleanup)
	return compoundMaid
end

--[[
	With StreamingEnabled, teleporting players to a new location can cause the following issues:

	- Chunk not loaded in. Very low quality or no instances loaded in at all.
	- Players with low-bandwidth will fall through the map (unless StreamingPauseMode == ClientPhysicsPause)
		(Because this pauses character physics until chunk is loaded sufficiently enough).

	This function resolves those issues by creating a request to stream a new area before teleporting the player.
	
	The chunk will have already started loading when the player gets teleported.

	NOTE: Most of the time, when using this function, the GameplayPausedNotifcation will not appear.
		This is because the chunk is usually loaded in before the player teleports, so Roblox won't have
		any reason to pause character physics.

		It's still important to have a notification though. Roblox provides a default one,
		but you can use .BindGameplayPauseNotifaction() to create custom GUI's when Roblox
		is streaming chunks and pausing character physics.

		This is useful because you can make more descriptive GUI's rather than just the original
		one which says "Gameplay Paused".

		If the player is teleporting, maybe you should make the GameplayPausedNotification say
			"Teleporting..."

		Or if you are loading the next level it could say
			"Loading next level..."
			
		If you use .BindGameplayPauseNotification() correclty, this GUI would only appear
		when the server is streaming instances to the client, and the client needs to wait for more
		instances to stream to ensure a playable environment.
]]

function StreamableUtil.TeleportPlayer(player, cFrame)
	if workspace.StreamingEnabled then
		player:RequestStreamAroundAsync(cFrame.Position)
	end

	local character = player.Character
	if character and character:WaitForChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = cFrame
	end
end

--[[
	Binds a callback that fires when the state of GameplayPaused changes. This allows developers
	to not only enable/disable GUI's when the server is streaming instances to the client and 
	the character physics are paused.
	
	Because of the callback nature of this function, you can pass callbacks that when executed,
	enable the respective GUI, and do other things like play animations for that GUI.

	USE CASE:

	In minecraft, when the player is teleported, a GUI comes up indicating that the player is teleporting.

	In the background, minecraft is streaming in new chuncks and unstreaming old chunks

	Using this method you can create a similar experience
]]

local _gameplayPausedChanged
local _callback

function StreamableUtil.BindGameplayPausedNotification(callback)
	assert(RunService:IsClient(), "This is a client only function.")
	assert(workspace.StreamingEnabled, "Streaming must be enabled [workspace.StreamingEnabled]")

	if callback then
		GuiService:SetGameplayPausedNotificationEnabled(false)
		_callback = callback
		if not _gameplayPausedChanged then
			local player = Players.LocalPlayer
			_gameplayPausedChanged = player:GetPropertyChangedSignal("GameplayPaused"):Connect(function()
				if player.GameplayPaused then
					print("GAMEPLAY PAUSED")
					_callback(true)
				else
					print("GAMEPLAY NO LONGER PAUSED")
					_callback(false)
				end
			end)
		end
	else
		GuiService:SetGameplayPausedNotificationEnabled(true)
		if _gameplayPausedChanged then
			_gameplayPausedChanged:Disconnect()
			_gameplayPausedChanged = nil
			_callback = nil
		end
	end
end

return StreamableUtil

--[[

	DEMO: TeleportPlayer and BindGameplayPausedNotification in action together:

	Notes: You rarely ever actually see the PausedNotifcation come up because roblox is pretty quick
	when it comes to streaming. If the world is bigger than you might start to see the GUI we've setup
	appear. If you do see it it's only for like .5 seconds because roblox streams everything in fast.
	
	
	
	
	
	
	
	
	CLIENT:
	
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = playerGui:WaitForChild("TeleportGui")
local frame = gui:WaitForChild("Frame")
local textLabel = frame:WaitForChild("TextLabel")

textLabel.Text = "TELEPORTING"
gui.Enabled = false

local StreamableUtil = require(ReplicatedStorage:WaitForChild("StreamableUtil"))

local GET_GAMEPLAY_PAUSED_STATE = ReplicatedStorage:WaitForChild("GetGameplayPausedState")

local isPaused = false

StreamableUtil.BindGameplayPausedNotification(function(paused)
	if paused then
		local pausedState = GET_GAMEPLAY_PAUSED_STATE:InvokeServer()
		isPaused = true
		gui.Enabled = true
		
		local count = 0
		if not isPaused then
			while isPaused do
				count += 1
				if count >= 3 then
					textLabel.Text = pausedState
				else
					textLabel.Text ..= "."
				end
				wait(1)
			end
			gui.Enabled = false
		end
	else
		isPaused = false
		gui.Enabled = false
	end
end)
















	SERVER:

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local StreamableUtil = require(ReplicatedStorage.StreamableUtil)

local GetGameplayPausedState = ReplicatedStorage.GetGameplayPausedState

local GameplayPausedState = {}
local defautlPauseState = "Loading Chunks"

local function SetPausedState(player, state)
	GameplayPausedState[player] = state
end

local function GSetPausedState(newState, map)
	for player, state in pairs(GameplayPausedState) do
		if map then
			GameplayPausedState[player] = map(state)
		else
			GameplayPausedState[player] = newState
		end
	end
end

local function GetPausedState(player)
	return GameplayPausedState[player]
end

local function TeleportPlayer(player, cFrame)
	SetPausedState(player, "Teleporting")
	StreamableUtil.TeleportPlayer(player, cFrame) -- yields
	if GetPausedState(player) then -- check to make sure the state has not changed. If it has that means another function has changed the state and there is no reason to revert back to None.
		SetPausedState(player, defautlPauseState)
	end
end

local function LoadLevel(levelName)
	local map = ServerStorage.Maps[levelName]
	if map then
		map = map:Clone()
		map.Parent = workspace

		local spawns = map:WaitForChild("Spawns"):GetChildren()

		for _, player in pairs(Players:GetPlayers()) do
			coroutine.wrap(function()
				local character = player.Character
				if character then
					SetPausedState(player, "LoadingLevel")
					StreamableUtil.TeleportPlayer(player, spawns[1].CFrame)
					table.remove(spawns, 1)
				else
					print(("%s not loaded, so not included in this round."):format(player.Name))
				end
			end)()
		end

		GSetPausedState("None", function(state)
			if state == "LoadingLevel" then
				return defautlPauseState
			else
				return state
			end
		end)
	else
		warn(("Attempt to load level %s, but level %s does not exist."):format(levelName, levelName))
	end
end

local function PlayerAdded(player)
	SetPausedState(player, defautlPauseState)
	wait(5)
	TeleportPlayer(player, workspace.Target.CFrame)
	wait(3)
	LoadLevel("level1")
end

local function PlayerRemoving(player)
	SetPausedState(player, nil)
end


GetGameplayPausedState.OnServerInvoke = function(player)
	return GetPausedState(player)
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

]]
