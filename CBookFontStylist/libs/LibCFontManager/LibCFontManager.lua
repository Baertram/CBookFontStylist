--
-- LibCFontManager [LCFM]
--
-- Copyright (c) 2019 Calamath
--
-- This software is released under the MIT License (X11 License).
-- https://choosealicense.com/licenses/mit/
--
-- Note :
-- This library addon works that uses the library LibMediaProvider-1.0 by Seerah, released under the LGPL-2.1 license.
-- You will need to obtain the above library separately.
--

if LibCFontManager then d("[LCFM] Warning : 'LibCFontManager' has always been loaded.") return end

-- Library
local LMP = LibMediaProvider
if not LMP then d("[LCFM] Error : 'LibMediaProvider' not found.") return end

-- Registeration of ESO bundled fonts to support Japanese language mode. These are not currently registered in LibMediaProvider.
LMP:Register("font", "JP-StdFont", "EsoUI/Common/Fonts/ESO_FWNTLGUDC70-DB.ttf")     -- JP-ESO Standard Font
LMP:Register("font", "JP-ChatFont", "EsoUI/Common/Fonts/ESO_FWUDC_70-M.ttf")        -- JP-ESO Chat Font
LMP:Register("font", "JP-KafuPenji", "EsoUI/Common/Fonts/ESO_KafuPenji-M.ttf")      -- JP-ESO Book Font

-- -------------------------------------------

LibCFontManager = {}
LibCFontManager.name = "LibCFontManager"
LibCFontManager.version = "0.1"
LibCFontManager.author = "Calamath"
LibCFontManager.savedVars = "LibCFontManagerDB" -- for testing purpose 
LibCFontManager.savedVarsVersion = 1            -- for testing purpose
LibCFontManager.isInitialized = false

local LCFM = LibCFontManager

-- -------------------------------------------

local lang = "en"
local isGamepad = false
local zosFontNum = 0
local unknownFontNum = 0

local lmpFontStyleList = {}
local lmpFontPathTable = {}
local lmpFontExTable = {}
local lmpFontFilenameToFontStyleLMP = {}  -- lowercase filename to FontStyleLMP


-- A data table used by this library to identify whether the font is an official bundled font or not.
local zosFontFilenameToFontStyleLMP = {   -- lowercase filename to FontStyleLMP
    ["univers55.otf"] = "Univers 55",                   -- 
    ["univers57.otf"] = "Univers 57",                   -- "MEDIUM_FONT""CHAT_FONT"
    ["univers67.otf"] = "Univers 67",                   -- "BOLD_FONT"
    ["eso_fwntlgudc70-db.ttf"] = "JP-StdFont",          -- JP-ESO bundled gothic font
    ["eso_fwudc_70-m.ttf"] = "JP-ChatFont",             -- JP-ESO bundled gothic condensed font
    ["eso_kafupenji-m.ttf"] = "JP-KafuPenji",           -- JP-ESO bundled hand written font
    ["ftn47.otf"] = "Futura Condensed Light",           -- "GAMEPAD_LIGHT_FONT"
    ["ftn57.otf"] = "Futura Condensed",                 -- "GAMEPAD_MEDIUM_FONT"
    ["ftn87.otf"] = "Futura Condensed Bold",            -- "GAMEPAD_BOLD_FONT"
    ["handwritten_bold.otf"] = "Skyrim Handwritten",    -- "HANDWRITTEN_FONT"
    ["proseantiquepsmt.otf"] = "ProseAntique",          -- "ANTIQUE_FONT"
    ["trajanpro-regular.otf"] = "Trajan Pro",           -- "STONE_TABLET_FONT"
    ["consola.ttf"] = "Consolas",                       -- 
}

-- in-game ZOS defined font list
local zosFontTable = {
    ZoFontWinH1                     = {}, 
    ZoFontWinH2                     = {}, 
    ZoFontWinH3                     = {}, 
    ZoFontWinH4                     = {}, 
    ZoFontWinH5                     = {}, 

    ZoFontWinH3SoftShadowThin       = {}, 

    ZoFontWinT1                     = {}, 
    ZoFontWinT2                     = {}, 

    ZoFontGame                      = {}, 
    ZoFontGameMedium                = {}, 
    ZoFontGameBold                  = {}, 
    ZoFontGameOutline               = {}, 
    ZoFontGameShadow                = {}, 

    ZoFontKeyboard28ThickOutline    = {}, 
    ZoFontKeyboard24ThickOutline    = {}, 
    ZoFontKeyboard18ThickOutline    = {}, 

    ZoFontGameSmall                 = {}, 
    ZoFontGameLarge                 = {}, 
    ZoFontGameLargeBold             = {}, 
    ZoFontGameLargeBoldShadow       = {}, 

    ZoFontHeader                    = {}, 
    ZoFontHeader2                   = {}, 
    ZoFontHeader3                   = {}, 
    ZoFontHeader4                   = {}, 

    ZoFontHeaderNoShadow            = {}, 

    ZoFontCallout                   = {}, 
    ZoFontCallout2                  = {}, 
    ZoFontCallout3                  = {}, 

    ZoFontEdit                      = {}, 
    ZoFontEdit20NoShadow            = {}, 

    ZoFontChat                      = {}, 
    ZoFontEditChat                  = {}, 

    ZoFontWindowTitle               = {}, 
    ZoFontWindowSubtitle            = {}, 

    ZoFontTooltipTitle              = {}, 
    ZoFontTooltipSubtitle           = {}, 

    ZoFontAnnounce                  = {}, 
    ZoFontAnnounceMessage           = {}, 
    ZoFontAnnounceMedium            = {}, 
    ZoFontAnnounceLarge             = {}, 

    ZoFontAnnounceLargeNoShadow     = {}, 
    
    ZoFontCenterScreenAnnounceLarge = {}, 
    ZoFontCenterScreenAnnounceSmall = {}, 

    ZoFontAlert                     = {}, 

    ZoFontConversationName          = {}, 
    ZoFontConversationText          = {}, 
    ZoFontConversationOption        = {}, 
    ZoFontConversationQuestReward   = {}, 

    ZoFontKeybindStripKey           = {}, 
    ZoFontKeybindStripDescription   = {}, 
    ZoFontDialogKeybindDescription  = {}, 

    ZoInteractionPrompt             = {}, 

    ZoFontCreditsHeader             = {}, 
    ZoFontCreditsText               = {}, 

    ZoFontSubtitleText              = {}, 

    ZoMarketAnnouncementCalloutFont = {}, 

--  <!-- In Game Book Fonts-->
    ZoFontBookPaper                 = {}, 
    ZoFontBookSkin                  = {}, 
    ZoFontBookRubbing               = {}, 
    ZoFontBookLetter                = {}, 
    ZoFontBookNote                  = {}, 
    ZoFontBookScroll                = {}, 
    ZoFontBookTablet                = {}, 
    ZoFontBookMetal                 = {}, 

--  <!-- In Game Book Title Fonts-->
    ZoFontBookPaperTitle            = {}, 
    ZoFontBookSkinTitle             = {}, 
    ZoFontBookRubbingTitle          = {}, 
    ZoFontBookLetterTitle           = {}, 
    ZoFontBookNoteTitle             = {}, 
    ZoFontBookScrollTitle           = {}, 
    ZoFontBookTabletTitle           = {}, 
    ZoFontBookMetalTitle            = {}, 


--  <!-- Generic Gamepad Fonts-->
    ZoFontGamepad61                 = {}, 
    ZoFontGamepad54                 = {}, 
    ZoFontGamepad45                 = {}, 
    ZoFontGamepad42                 = {}, 
    ZoFontGamepad36                 = {}, 
    ZoFontGamepad34                 = {}, 
    ZoFontGamepad27                 = {}, 
    ZoFontGamepad25                 = {}, 
    ZoFontGamepad22                 = {}, 
    ZoFontGamepad20                 = {}, 
    ZoFontGamepad18                 = {}, 

    ZoFontGamepad27NoShadow         = {}, 
    ZoFontGamepad42NoShadow         = {}, 

    ZoFontGamepad36ThickOutline     = {}, 
    
    ZoFontGamepadCondensed61        = {}, 
    ZoFontGamepadCondensed54        = {}, 
    ZoFontGamepadCondensed45        = {}, 
    ZoFontGamepadCondensed42        = {}, 
    ZoFontGamepadCondensed36        = {}, 
    ZoFontGamepadCondensed34        = {}, 
    ZoFontGamepadCondensed27        = {}, 
    ZoFontGamepadCondensed25        = {}, 
    ZoFontGamepadCondensed22        = {}, 
    ZoFontGamepadCondensed20        = {}, 
    ZoFontGamepadCondensed18        = {}, 

    ZoFontGamepadBold61             = {}, 
    ZoFontGamepadBold54             = {}, 
    ZoFontGamepadBold48             = {}, 
    ZoFontGamepadBold34             = {}, 
    ZoFontGamepadBold27             = {}, 
    ZoFontGamepadBold25             = {}, 
    ZoFontGamepadBold22             = {}, 
    ZoFontGamepadBold20             = {}, 
    ZoFontGamepadBold18             = {}, 
    
    ZoFontGamepadChat               = {}, 
    ZoFontGamepadEditChat           = {}, 
    
--  <!-- In Game Book Fonts-->
    ZoFontGamepadBookPaper          = {}, 
    ZoFontGamepadBookSkin           = {}, 
    ZoFontGamepadBookRubbing        = {}, 
    ZoFontGamepadBookLetter         = {}, 
    ZoFontGamepadBookNote           = {}, 
    ZoFontGamepadBookScroll         = {}, 
    ZoFontGamepadBookTablet         = {}, 
    ZoFontGamepadBookMetal          = {}, 
    
--  <!-- In Game Book Title Fonts-->
    ZoFontGamepadBookPaperTitle     = {}, 
    ZoFontGamepadBookSkinTitle      = {}, 
    ZoFontGamepadBookRubbingTitle   = {}, 
    ZoFontGamepadBookLetterTitle    = {}, 
    ZoFontGamepadBookNoteTitle      = {}, 
    ZoFontGamepadBookScrollTitle    = {}, 
    ZoFontGamepadBookTabletTitle    = {}, 
    ZoFontGamepadBookMetalTitle     = {}, 
    
--  <!-- Header fonts-->
    ZoFontGamepadHeaderDataValue    = {}, 
    
--  <!-- Market fonts-->
    ZoMarketGamepadCalloutFont      = {}, 
}

-- ------------------------------------------------


local function GetFilename(filePath)
    if filePath then
        return zo_strmatch(filePath, "[^/]+$")
    end
end

local function GetAddonPath(filePath)
    if filePath then
        return zo_strmatch(filePath, "^/?([^/]+)/")
    end
end

local function GetFileExtension(filename)
    if filename then
        filenameWithoutExt, ext = zo_strmatch(filename, "(.+)%.([^%.]+)$")
        if ext == nil then
            filenameWithoutExt = filename
        end
        return ext, filenameWithoutExt
    end
end

local function GetTableKeyForValue(table, value)
    for k, v in pairs(table) do
        if v == value then 
            return k
        end
    end
    return nil
end

local function Decolorize(str)
    if type(str) == "string" then
        return str:gsub("|c%x%x%x%x%x%x", ""):gsub("|r", "")
    else
        return str
    end
end

local function localMakeFontDescriptor(fontPath, size, weight)
-- 'fontPath' should contain a valid filepath string of the target font file.
    local formatStr = "%s|%d"

    if weight or weight ~= "" then
        weight = zo_strlower(weight)
        if weight ~= "normal" then
            formatStr = formatStr .. "|%s"
        end
    end
    return string.format(formatStr, fontPath, size, weight)
end

local function GetFontStyleForValue(fontPath)
    local filename = zo_strlower(GetFilename(fontPath))
    local fontStyleLMP
    fontStyleLMP = zosFontFilenameToFontStyleLMP[filename]  -- first, look in the eso core font table.
    if fontStyleLMP then
        return fontStyleLMP, true
    end
    fontStyleLMP = lmpFontFilenameToFontStyleLMP[filename]  -- second, look in the LMP font table.
    if fontStyleLMP then
        return fontStyleLMP, false
    end
end

local function AppendUnknownFontToLMP(fontPath) -- for fail-safe
--- if someone use the font not registered yet in LibMediaProvider, ...
    if type(fontPath) == "string" then
        unknownFontNum = unknownFontNum + 1
        local _, noextFilename = GetFileExtension(GetFilename(fontPath))
        local fontStyle = string.format("$LCFM_%s", noextFilename)
        LMP:Register("font", fontStyle, fontPath)
        return fontStyle
    end
end

-- ------------------------------------------------------

local function InitializeLCFM()
    lang = GetCVar("Language.2")
    isGamepad = IsInGamepadPreferredMode()
    zosFontNum = 0
    unknownFontNum = 0

-- for font management enhancements, this feature work with LibMediaProvider.
    lmpFontStyleList = ZO_ShallowTableCopy(LMP:List("font"))    -- LCFM uses an own local copy of the LMP font media list. It is not sorted after each registration in LMP from now.
    lmpFontPathTable = ZO_ShallowTableCopy(LMP:HashTable("font"))
    for i, key in pairs(lmpFontStyleList) do
        local fontPath = lmpFontPathTable[key]

        local filename = zo_strlower(GetFilename(fontPath))
        lmpFontFilenameToFontStyleLMP[filename] = key

        lmpFontExTable[key] = {}
        lmpFontExTable[key].provider = GetAddonPath(fontPath) or "$$LCFM_unknown"
        lmpFontExTable[key].filename = filename
        if zosFontFilenameToFontStyleLMP[filename] then
            lmpFontExTable[key].isOfficial = true
        else
            lmpFontExTable[key].isOfficial = false
        end
    end
    CALLBACK_MANAGER:RegisterCallback("LibMediaProvider_Registered", function(mediatype, key)   -- callback routine to ensure consistency with the LMP font list after local copy.
        if mediatype == "font" then return end
        table.insert(lmpFontStyleList, key)
        local fontPath = LMP:Fetch("font", key)
        lmpFontPathTable[key] = fontPath

        local filename = zo_strlower(GetFilename(fontPath))
        lmpFontFilenameToFontStyleLMP[filename] = key

        lmpFontExTable[key] = {}
        lmpFontExTable[key].provider = GetAddonPath(fontPath) or "$$LCFM_unknown"
        lmpFontExTable[key].filename = filename
        if zosFontFilenameToFontStyleLMP[filename] then
            lmpFontExTable[key].isOfficial = true
        else
            lmpFontExTable[key].isOfficial = false
        end
    end)

-- for preserve the initial state of the zos fonts in various game mode environments,
    for k, v in pairs(zosFontTable) do
        if _G[k] ~= nil then
            v.objName = k   -- for debug
            v.fontPath, v.size, v.weight = _G[k]:GetFontInfo()
            if not v.weight or v.weight == "" then
                v.weight = "normal"
            end
            v.descriptor = localMakeFontDescriptor(v.fontPath, v.size, v.weight)    -- for debug
            v.style, v.isOfficial = GetFontStyleForValue(v.fontPath)
            if not v.style then
                v.style, v.isOfficial = AppendUnknownFontToLMP(v.fontPath) or "$$LCFM_unknown", false
            end
            v.provider = GetAddonPath(v.fontPath) or "$$LCFM_unknown"   -- for debug
            v.isModified = false
            zosFontNum = zosFontNum + 1
        else
            d("[LCFM] Warning : zosFont '" .. tostring(k) .. "' is deleted!")
            zosFontTable[k] = nil
        end
    end
end


local function OnAddOnLoaded(event, addonName)
    if addonName ~= LCFM.name then return end
    EVENT_MANAGER:UnregisterForEvent(LCFM.name, EVENT_ADD_ON_LOADED)

    InitializeLCFM()
    LCFM.isInitialized = true
--  d("[LCFM] Initialized")
end
EVENT_MANAGER:RegisterForEvent(LCFM.name, EVENT_ADD_ON_LOADED, OnAddOnLoaded)





-- ------------------------------------------------------------------------------------------------

function LibCFontManager:MakeFontDescriptor(fontPath, size, weight)
    return localMakeFontDescriptor(fontPath, size, weight)
end

function LibCFontManager:MakeFontDescriptorLMP(style, size, weight)
-- 'style' should contain a valid handle string of the LibMediaProvider font table.
    if type(style) == "string" then
        local fontPath = LMP:Fetch("font", style)
        if fontPath then
            return localMakeFontDescriptor(fontPath, size, weight)
        end
    end
end

-- ------------------------------------------------------------------------------------------------
function LibCFontManager:GetFontStyleListLMP()
    return lmpFontStyleList
end

function LibCFontManager:GetDecoratedFontStyleListLMP()
    local t = {}
    for k, v in pairs(lmpFontStyleList) do
        if lmpFontExTable[v].isOfficial then
            t[k] = "|c4169e1" .. v .. "|r"
        else
            t[k] = v
        end
    end
    return t
end

-- ------------------------------------------------------------------------------------------------

function LibCFontManager:GetDefaultFontInfo(objName)
    local tbl = zosFontTable[objName]
    if tbl then
        local weight = tbl.weight
        if weight == "normal" then weight = nil end
        return tbl.fontPath, tbl.size, weight
    end
end

function LibCFontManager:GetDefaultFontInfoLMP(objName)
    local tbl = zosFontTable[objName]
    if tbl then
        return tbl.style, tbl.size, tbl.weight
    end
end

function LibCFontManager:GetDefaultFontDescriptor(objName)
    local tbl = zosFontTable[objName]
    if tbl then
        return tbl.descriptor
    end
end

function LibCFontManager:RestoreToDefaultFont(objName)
    local tbl = zosFontTable[objName]
    if tbl then
        _G[objName]:SetFont(tbl.descriptor)
        tbl.isModified = false
    end
end

function LibCFontManager:SetToNewFont(objName, fontDescriptor)
    local tbl = zosFontTable[objName]
    if tbl then
        _G[objName]:SetFont(fontDescriptor)
        tbl.isModified = true
    end
end

function LibCFontManager:SetToNewFontLMP(objName, style, size, weight)
    local fontDescriptor = self:MakeFontDescriptorLMP(style, size, weight)
    if fontDescriptor then
        self:SetToNewFont(objName, fontDescriptor)
    end
end



-- ------------------------------------------------
--[[
SLASH_COMMANDS["/lcfm.debug"] = function(arg)
    -- for debug
    local db_default = {
        lmpFontStyleList = lmpFontStyleList, 
        lmpFontPathTable = lmpFontPathTable, 
        lmpFontExTable = lmpFontExTable, 
        lmpFontFilenameToFontStyleLMP = lmpFontFilenameToFontStyleLMP, 
        zosFontTable = zosFontTable, 
        unknownFontNum = unknownFontNum, 
    }
    LCFM.db = ZO_SavedVars:NewAccountWide(LCFM.savedVars, LCFM.savedVarsVersion, nil, db_default)
end
]]