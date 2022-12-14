local f = CreateFrame("Frame")
f:RegisterEvent("BAG_UPDATE_DELAYED")
f:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")

local bagID, slotID

local function unequipUA()
    bagID, slotID = nil
    
    -- find the first empty bag slot
    for b = 0, 4 do
        if C_Container.GetContainerNumFreeSlots(b) > 0 then
            for s = 1, C_Container.GetContainerNumSlots(b) do
                if not C_Container.GetContainerItemID(b, s) then
                    bagID, slotID = b, s
                    break
                end
            end
            break
        end
    end

    -- player does not have space in their bags
    if not bagID then return end

    -- put the fishing tool onto the cursor
    PickupInventoryItem(ProfessionsFrame.CraftingPage.FishingToolSlot:GetID())
    
    -- put the fishing tool into the bags
    C_Container.PickupContainerItem(bagID, slotID)
end

local function reequipUA()
    -- put the fishing tool back onto the cursor
    C_Container.PickupContainerItem(bagID, slotID)
    
    -- put the cursor item (underlight angler) into the fishing tool slot
    PickupInventoryItem(ProfessionsFrame.CraftingPage.FishingToolSlot:GetID())
    
    bagID, slotID = nil
end

local throttle = GetTime()

f:SetScript("OnEvent", function(self, event, ...)
    if event == "BAG_UPDATE_DELAYED" then
        if bagID and slotID then
            if InCombatLockdown() then return end
            reequipUA()
        end
    elseif (event == "MOUNT_JOURNAL_USABILITY_CHANGED") or (event == "PLAYER_REGEN_ENABLED") then
        if InCombatLockdown() then return end
        
        -- IsSwimming returns false during the MOUNT_JOURNAL_USABILITY_CHANGED event, so add a small delay
        C_Timer.After(0.1, function()
            
            -- the MOUNT_JOURNAL_USABILITY_CHANGED event fires twice when entering water; only trigger on the first one
            if (throttle + 1) > GetTime() then return end
            
            -- cannot change items while in combat
            if InCombatLockdown() then return end
            
            -- only do something if the player has Underlight Angler equipped
            if GetInventoryItemID("player", ProfessionsFrame.CraftingPage.FishingToolSlot:GetID()) ~= 133755 then return end
            
            
            -- if the player already has the Fishing for Attention buff, do nothing
            if C_UnitAuras.GetPlayerAuraBySpellID(394009) then return end
            
            if IsSwimming() then
                unequipUA()
                throttle = GetTime()
            end
        end)
    end
end)