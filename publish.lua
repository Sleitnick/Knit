-- Remodel Publish script

local KNIT_ASSET_ID = "5530714855"

print("Loading Knit")
local place = remodel.readPlaceFile("Knit.rbxlx")
local Knit = place.ReplicatedStorage.Knit

print("Writing Knit module to Roblox...")
remodel.writeExistingModelAsset(Knit, KNIT_ASSET_ID)

print("Knit module written")