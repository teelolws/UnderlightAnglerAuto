local f = CreateFrame("Frame")
f:RegisterEvent("BAG_UPDATE")
f:RegisterEvent("MOUNT_JOURNAL_USABILITY_CHANGED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("CHAT_MSG_LOOT")

local emptyBagID, emptySlotID, usedBagID, usedSlotID

local function unequipUA()
    emptyBagID, emptySlotID = nil
    
    -- find the first empty bag slot
    for b = 0, 4 do
        if C_Container.GetContainerNumFreeSlots(b) > 0 then
            for s = 1, C_Container.GetContainerNumSlots(b) do
                if not C_Container.GetContainerItemID(b, s) then
                    emptyBagID, emptySlotID = b, s
                    break
                end
            end
            break
        end
    end

    -- player does not have space in their bags
    if not emptyBagID then return end

    -- put the fishing tool onto the cursor
    PickupInventoryItem(ProfessionsFrame.CraftingPage.FishingToolSlot:GetID())
    
    -- put the fishing tool into the bags
    C_Container.PickupContainerItem(emptyBagID, emptySlotID)
end

local function reequipUA()
    -- put the fishing tool back onto the cursor
    C_Container.PickupContainerItem(emptyBagID, emptySlotID)
    
    -- put the cursor item (underlight angler) into the fishing tool slot
    PickupInventoryItem(ProfessionsFrame.CraftingPage.FishingToolSlot:GetID())
    
    emptyBagID, emptySlotID = nil
end

local function switchInUA()
    -- put the UA on the cursor
    C_Container.PickupContainerItem(usedBagID, usedSlotID)
    
    -- put the cursor item (UA) into the fishing tool slot
    PickupInventoryItem(ProfessionsFrame.CraftingPage.FishingToolSlot:GetID())
end

local function switchOutUA()
    PickupInventoryItem(ProfessionsFrame.CraftingPage.FishingToolSlot:GetID())
    C_Container.PickupContainerItem(usedBagID, usedSlotID)
end

local throttle = GetTime()

f:SetScript("OnEvent", function(self, event, ...)
    if InCombatLockdown() or C_ChallengeMode.IsChallengeModeActive() then return end
    
    if event == "BAG_UPDATE" then
        if emptyBagID and emptySlotID then
            reequipUA()
        end
    elseif event == "MOUNT_JOURNAL_USABILITY_CHANGED" then
        -- IsSwimming returns false during the MOUNT_JOURNAL_USABILITY_CHANGED event, so add a small delay
        RunNextFrame(function()
            if InCombatLockdown() or C_ChallengeMode.IsChallengeModeActive() then return end
            if emptyBagID then return end
            
            -- the MOUNT_JOURNAL_USABILITY_CHANGED event fires twice when entering water; only trigger on the first one
            if (throttle + 0.2) > GetTime() then return end
            
            -- if we just switched the UA in, replacing a profession tool, and the player left the water, lets swap the profession tool back in
            if usedBagID and (not IsSwimming()) and (GetInventoryItemID("player", ProfessionsFrame.CraftingPage.FishingToolSlot:GetID()) == 133755) then
                switchOutUA()
                throttle = GetTime()
                return
            end
            
            -- if the player already has the UA equipped and has the Fishing for Attention buff, do nothing
            if (GetInventoryItemID("player", ProfessionsFrame.CraftingPage.FishingToolSlot:GetID()) == 133755) and 
                C_UnitAuras.GetPlayerAuraBySpellID(394009) then
                    return
            end
            
            -- if the player has UA equipped, no buff, and we aren't already using switch mode, then unequip UA
            if (GetInventoryItemID("player", ProfessionsFrame.CraftingPage.FishingToolSlot:GetID()) == 133755) and (not usedBagID) then
                if IsSwimming() then
                    unequipUA()
                    throttle = GetTime()
                    return
                end
            end
            
            -- does player have UA in their bags?
            for b = 0, 4 do
                for s = 1, C_Container.GetContainerNumSlots(b) do
                    if C_Container.GetContainerItemID(b, s) == 133755 then
                        usedBagID = b
                        usedSlotID = s
                        if IsSwimming() then
                            switchInUA()
                        end
                        return
                    end
                end
            end
        end)
    elseif (event == "PLAYER_REGEN_ENABLED") and emptyBagID and emptySlotID then
        reequipUA()
    elseif (event == "PLAYER_REGEN_ENABLED") or (event == "CHAT_MSG_LOOT") then
        if GetInventoryItemID("player", ProfessionsFrame.CraftingPage.FishingToolSlot:GetID()) ~= 133755 then return end
        if C_UnitAuras.GetPlayerAuraBySpellID(394009) then return end
        if IsSwimming() then
            unequipUA()
        end
    end
end)
