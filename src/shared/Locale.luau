-- Shared.Locale (track I): English + Thai. English text is the key (gettext style); Thai lives in
-- Config.Strings (UI text, generated from assets/localization/strings.csv) plus the `.thai` fields of
-- catalog configs (weapons, pets, seeds, eggs, zones). Templates use {1}, {2}... for dynamic parts.
--   Locale.T("Fused to ★{1}", {5})        -> "หลอมเป็น ★5" when Thai is active
--   Locale.Translate(anyDisplayedText)     -> exact match, then templates (slots translated recursively)
--   Locale.Bind(root)                      -> client: keeps every TextLabel/TextButton/TextBox placeholder and
--                                            ProximityPrompt under root translated, also when code changes the text
-- Language: Settings.Language "Auto" | "en" | "th"; Auto = Roblox locale (th* -> Thai, else English).
local RunService = game:GetService("RunService")
local Shared = script.Parent
local Strings = require(Shared.Config.Strings)

local Locale = {}
Locale.Languages = { "Auto", "en", "th" }
local lang = "en"
local changed = Instance.new("BindableEvent")
Locale.Changed = changed.Event

local th: { [string]: string } = {}
for k, v in Strings.th do
	th[k] = v
end
-- Catalog names with authored Thai (weapons, pets, seeds, eggs, zones) — never duplicated in Strings.
local function addNames(list)
	for _, def in list do
		if type(def) == "table" and type(def.name) == "string" and type(def.thai) == "string" and def.thai:find("[\224]") and th[def.name] == nil then
			th[def.name] = def.thai
		end
	end
end
for _, name in { "WeaponCatalog", "Pets", "Seeds", "Eggs", "Zones" } do
	local ok, cfg = pcall(require, Shared.Config:FindFirstChild(name))
	if ok and type(cfg) == "table" then
		addNames(cfg.List or {})
		if name == "WeaponCatalog" then
			addNames(cfg.Legacy or {})
		end
	end
end

-- Templates: "Level {1} • ×{2}" -> Lua pattern; longest literal first so specific beats generic.
local templates = {}
for key, value in th do
	if key:find("{%d+}") then
		local literal = key:gsub("{%d+}", "")
		if #literal:gsub("%s", "") >= 2 then
			local order, pattern = {}, "^"
			local last = 1
			for s, n, e in key:gmatch("()({%d+})()") do
				pattern ..= key:sub(last, s - 1):gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "(.-)"
				table.insert(order, tonumber(n:sub(2, -2)))
				last = e
			end
			pattern ..= key:sub(last):gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0") .. "$"
			table.insert(templates, { pattern = pattern, order = order, value = value, weight = #literal })
		end
	end
end
table.sort(templates, function(a, b)
	return a.weight > b.weight
end)

function Locale.Lang(): string
	return lang
end

function Locale.Resolve(setting: string?, localeId: string?): string
	if setting == "en" or setting == "th" then
		return setting
	end
	return (type(localeId) == "string" and localeId:lower():sub(1, 2) == "th") and "th" or "en"
end

function Locale.SetLang(new: string)
	new = (new == "th") and "th" or "en"
	if new ~= lang then
		lang = new
		changed:Fire(lang)
	end
end

local function fill(text: string, vars: { [any]: any }?): string
	if not vars then
		return text
	end
	return (text:gsub("{(%w+)}", function(k)
		local v = vars[tonumber(k) or k]
		return v ~= nil and tostring(v) or "{" .. k .. "}"
	end))
end

-- Explicit lookup for new code: Locale.T(key, vars). Missing Thai falls back to English.
function Locale.T(key: string, vars: { [any]: any }?): string
	local text = (lang == "th" and th[key]) or key
	return fill(text, vars)
end

local cache: { [string]: string } = {}
local cacheSize = 0
local function translate(text: string, depth: number): string
	if text == "" or not text:find("%a") then
		return text
	end
	local hit = th[text]
	if hit then
		return hit
	end
	local lead, body, tail = text:match("^(%s*)(.-)(%s*)$")
	if body ~= text and th[body] then
		return lead .. th[body] .. tail
	end
	for _, t in templates do
		local caps = { body:match(t.pattern) }
		if caps[1] ~= nil then
			local vals = {}
			for i, slot in t.order do
				vals[slot] = depth < 2 and translate(caps[i], depth + 1) or caps[i]
			end
			return lead .. fill(t.value, vals) .. tail
		end
	end
	if body:find("\n") then -- multi-line text assembled from separate sentences
		local out = {}
		for _, line in body:split("\n") do
			table.insert(out, translate(line, depth + 1))
		end
		return lead .. table.concat(out, "\n") .. tail
	end
	return text
end

function Locale.Translate(text: string): string
	if lang == "en" or type(text) ~= "string" then
		return text
	end
	local c = cache[text]
	if c then
		return c
	end
	local out = translate(text, 0)
	if cacheSize > 4000 then
		table.clear(cache)
		cacheSize = 0
	end
	cache[text] = out
	cacheSize += 1
	return out
end

Locale.Has = function(text: string): boolean
	return th[text] ~= nil
end

-- Client binding ------------------------------------------------------------------------------------
if RunService:IsClient() then
	local source: { [Instance]: { [string]: string } } = setmetatable({}, { __mode = "k" }) :: any
	local shown: { [Instance]: { [string]: string } } = setmetatable({}, { __mode = "k" }) :: any
	local PROPS = { TextLabel = { "Text" }, TextButton = { "Text" }, TextBox = { "PlaceholderText" }, ProximityPrompt = { "ActionText", "ObjectText" } }

	local function apply(inst: Instance, prop: string)
		local src = source[inst] and source[inst][prop]
		if src == nil then
			return
		end
		local out = Locale.Translate(src)
		shown[inst] = shown[inst] or {}
		shown[inst][prop] = out
		if (inst :: any)[prop] ~= out then
			(inst :: any)[prop] = out
		end
	end

	local function track(inst: Instance)
		local props = PROPS[inst.ClassName]
		if not props or source[inst] or inst:GetAttribute("NoTranslate") then
			return
		end
		source[inst] = {}
		for _, prop in props do
			source[inst][prop] = (inst :: any)[prop]
			apply(inst, prop)
			inst:GetPropertyChangedSignal(prop):Connect(function()
				local now = (inst :: any)[prop]
				if shown[inst] and shown[inst][prop] == now then
					return -- our own write
				end
				source[inst][prop] = now -- game code set new (English) text
				apply(inst, prop)
			end)
		end
	end

	function Locale.Bind(root: Instance)
		for _, d in root:GetDescendants() do
			track(d)
		end
		root.DescendantAdded:Connect(track)
	end

	Locale.Changed:Connect(function()
		table.clear(cache)
		cacheSize = 0
		for inst, props in source do
			if inst.Parent then
				for prop in props do
					apply(inst, prop)
				end
			end
		end
	end)
end

return Locale
