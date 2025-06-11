local helpers = {}

local ENTITY_FILTER = {
	proxyent_tf2itempaint = true,
	proxyent_tf2critglow = true,
	proxyent_tf2cloakeffect = true,
}

local MODEL_FILTER = {
	["models/error.mdl"] = true,
}

---Get a vector from a `%f %f %f` string
---@param str string
---@param component integer?
---@returns Vector|number
function helpers.vectorFromString(str, component)
	local direction = string.Split(str, " ")
	if component and component > 0 and component < 4 then
		return tonumber(direction[component])
	end
	return Vector(tonumber(direction[1]), tonumber(direction[2]), tonumber(direction[3]))
end

---Get a nicely formatted model name
---@param entity Entity
---@return string
function helpers.getModelNameNice(entity)
	local mdl = string.Split(entity:GetModel() or "", "/")
	mdl = mdl[#mdl]
	return string.NiceName(string.sub(mdl, 1, #mdl - 4))
end

---Get the model name without the path
---@param entity Entity
---@return string
function helpers.getModelName(entity)
	local mdl = string.Split(entity:GetModel(), "/")
	mdl = mdl[#mdl]
	return mdl
end

---Get a filtered array of the entity's children
---@param entity Entity
---@return Entity[]
function helpers.getValidModelChildren(entity)
	local filteredChildren = {}
	for i, child in ipairs(entity:GetChildren()) do
		if
			child.GetModel
			and child:GetModel()
			and not IsUselessModel(child:GetModel())
			and not MODEL_FILTER[child:GetModel()]
			and not ENTITY_FILTER[child:GetClass()]
		then
			table.insert(filteredChildren, child)
		end
	end
	return filteredChildren
end

local modelSkins = {}

---Grab the entity's model icon
---@source https://github.com/NO-LOAFING/AdvBonemerge/blob/371b790d00d9bcbb62845ce8785fc6b98fbe8ef4/lua/weapons/gmod_tool/stools/advbonemerge.lua#L1079
---@param ent Entity
---@param model string?
---@param skin integer?
---@return string iconPath
function helpers.getModelNodeIconPath(ent, model, skin)
	skin = skin or ent:GetSkin() or 0
	model = model or ent:GetModel()

	if modelSkins[model .. skin] then
		return modelSkins[model .. skin]
	end

	local modelicon = "spawnicons/" .. string.StripExtension(model) .. ".png"
	local fallback = file.Exists("materials/" .. modelicon, "GAME") and modelicon or "icon16/bricks.png"
	if skin > 0 then
		modelicon = "spawnicons/" .. string.StripExtension(model) .. "_skin" .. skin .. ".png"
	end

	if not file.Exists("materials/" .. modelicon, "GAME") then
		modelicon = fallback
	else
		modelSkins[model .. skin] = modelicon
	end

	return modelicon
end

-- Cache the sorted indices so we don't iterate two more times than necessary
local sortedIndicesDictionary = {}

---Helper function to iterate over an array with nonconsecutive integers ("holes" in the middle of the array, or zero or negative indices)
---@source https://subscription.packtpub.com/book/game-development/9781849515504/1/ch01lvl1sec14/extending-ipairs-for-use-in-sparse-arrays
---@generic T
---@param t T[] Table to iterate over
---@param identifier string A unique key to store the table's sorted indices
---@param changed boolean? Has the table's state in some way?
---@return fun(): integer, T
function helpers.ipairs_sparse(t, identifier, changed)
	-- tmpIndex will hold sorted indices, otherwise
	-- this iterator would be no different from pairs iterator
	local tmpIndex = {}

	if changed or not sortedIndicesDictionary[identifier] then
		local index, _ = next(t)
		while index do
			tmpIndex[#tmpIndex + 1] = index
			index, _ = next(t, index)
		end

		-- sort table indices
		table.sort(tmpIndex)

		sortedIndicesDictionary[identifier] = tmpIndex
	else
		tmpIndex = sortedIndicesDictionary[identifier]
	end
	local j = 1
	-- get index value
	return function()
		local i = tmpIndex[j]
		j = j + 1
		if i then
			return i, t[i]
		end
	end
end

---Calculate the bone offsets with respect to the parent
---@source https://github.com/NO-LOAFING/AnimpropOverhaul/blob/a3a6268a5d57655611a8b8ed43dcf43051ecd93a/lua/entities/prop_animated.lua#L1889
---@param entity Entity Entity to obtain bone information
---@param child integer Child bone index
---@param vector Vector
---@return Angle angleOffset Angle of child bone with respect to parent bone
function helpers.getBoneOffsetsFromVector(entity, child, vector)
	local defaultBonePose = helpers.getDefaultPoseTree(entity)

	local parent = entity:GetBoneParent(child)
	---@type VMatrix
	local cMatrix = entity:GetBoneMatrix(child)
	---@type VMatrix
	local pMatrix = entity:GetBoneMatrix(parent)

	if not cMatrix or not pMatrix or not defaultBonePose or #defaultBonePose == 0 then
		return angle_zero * 1
	end

	local fPos, fAng = WorldToLocal(
		cMatrix:GetTranslation(),
		vector:AngleEx(pMatrix:GetAngles():Up()),
		pMatrix:GetTranslation(),
		pMatrix:GetAngles()
	)

	local m = Matrix()
	m:Translate(defaultBonePose[parent].oPos)
	m:Rotate(defaultBonePose[parent].oAng)
	m:Rotate(fAng)

	local _, dAng =
		WorldToLocal(m:GetTranslation(), m:GetAngles(), defaultBonePose[child].oPos, defaultBonePose[child].oAng)

	return dAng
end

return helpers
