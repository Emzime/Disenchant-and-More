-- DeM v3: two keys, no macro, no action bar.
-- Hover an item in your bags and press:
--   * key 1 -> SPELL_1 on the item
--   * key 2 -> SPELL_2 on the item
-- No modifier detection: works with mice that turn Shift+Numpad0 into Insert.

local SPELL_1 = "Compréhension de parchemin"
local SPELL_2 = "Désenchanter"

-- Keybinding menu labels
BINDING_HEADER_DEM = "DeM"
_G["BINDING_NAME_CLICK DeMKey1:LeftButton"] = SPELL_1 .. " sur l'objet survolé"
_G["BINDING_NAME_CLICK DeMKey2:LeftButton"] = SPELL_2 .. " sur l'objet survolé"

local debug = false
local function Print(...)
    if debug then print("|cff33ff99DeM:|r", ...) end
end

-- Returns the frame currently under the mouse cursor (new and old API)
local function GetFocus()
    if GetMouseFoci then
        return GetMouseFoci()[1]
    elseif GetMouseFocus then
        return GetMouseFocus()
    end
end

-- Returns bag, slot of the hovered bag item button, or nil
local function GetHoveredBagSlot()
    local b = GetFocus()
    if not (b and b.GetID) then return end
    local slot = b:GetID()
    local bag
    if b.GetBagID then
        bag = b:GetBagID()
    elseif b:GetParent() and b:GetParent().GetID then
        bag = b:GetParent():GetID()
    end
    if bag and slot and slot > 0 then return bag, slot end
end

-- Creates a hidden secure button that casts SPELL on the hovered bag item
local function CreateKeyButton(name, spell)
    local f = CreateFrame("Button", name, UIParent, "SecureActionButtonTemplate")
    f:SetAttribute("type", "macro")
    f:SetAttribute("macrotext", "")
    f:RegisterForClicks("AnyUp", "AnyDown")

    -- Runs (insecure) just before the secure action: builds the macro text
    f:SetScript("PreClick", function(self, button, down)
        if InCombatLockdown() then return end

        -- Only act once per key press, on the phase the game uses for actions
        if (down and true or false) ~= GetCVarBool("ActionButtonUseKeyDown") then
            self:SetAttribute("macrotext", "")
            return
        end

        local bag, slot = GetHoveredBagSlot()
        if not bag then
            self:SetAttribute("macrotext", "")
            Print(name, "pressed, but no bag item under the mouse")
            return
        end

        self:SetAttribute("macrotext", "/cast " .. spell .. "\n/use " .. bag .. " " .. slot)
        Print(name, "->", spell, "on bag", bag, "slot", slot)
    end)
end

CreateKeyButton("DeMKey1", SPELL_1)
CreateKeyButton("DeMKey2", SPELL_2)

-- Binds key1 to DeMKey1 and key2 to DeMKey2
local function BindKeys(key1, key2)
    if InCombatLockdown() then
        print("|cff33ff99DeM:|r impossible en combat")
        return
    end
    key1, key2 = key1:upper(), key2:upper()
    SetBinding(key1, "CLICK DeMKey1:LeftButton")
    SetBinding(key2, "CLICK DeMKey2:LeftButton")
    SaveBindings(GetCurrentBindingSet())
    print("|cff33ff99DeM:|r " .. key1 .. " = " .. SPELL_1 .. ", " .. key2 .. " = " .. SPELL_2)
end

-- Debug: prints the name of every key pressed (to find what the mouse sends)
local keyWatcher = CreateFrame("Frame")
keyWatcher:SetPropagateKeyboardInput(true)
keyWatcher:SetScript("OnKeyDown", function(_, key) Print("key pressed:", key) end)
keyWatcher:EnableKeyboard(false)

-- /dem             : toggle debug messages (also shows pressed key names)
-- /dem bind K1 K2  : bind K1 (spell 1) and K2 (spell 2)
SLASH_DEM1 = "/dem"
SlashCmdList.DEM = function(msg)
    local cmd, a, b = msg:match("^(%S*)%s*(%S*)%s*(%S*)")
    if cmd == "bind" and a ~= "" and b ~= "" then
        BindKeys(a, b)
    else
        debug = not debug
        if not InCombatLockdown() then keyWatcher:EnableKeyboard(debug) end
        print("|cff33ff99DeM:|r debug " .. (debug and "ON" or "OFF"))
    end
end
