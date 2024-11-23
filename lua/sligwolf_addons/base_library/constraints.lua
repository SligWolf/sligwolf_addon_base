AddCSLuaFile()
local SligWolf_Addons = SligWolf_Addons

if not SligWolf_Addons then
	return
end

if not SligWolf_Addons.LoadingLibraries then
	SligWolf_Addons.ReloadAllAddons()
	return
end

SligWolf_Addons.Constraints = SligWolf_Addons.Constraints or {}
table.Empty(SligWolf_Addons.Constraints)

local LIB = SligWolf_Addons.Constraints

local CONSTANTS = SligWolf_Addons.Constants

local constraint = constraint

local function enrichConstraintEntityData(constraintEnt)
	constraintEnt.DoNotDuplicate = true
	constraintEnt.sligwolf_entity = true
	constraintEnt.sligwolf_constraintEntity = true
end

function LIB.Weld(ent, parent, constraintInfos)
	constraintInfos = constraintInfos or {}

	local constraintEnt = constraint.Weld(
		ent,
		parent,
		constraintInfos.bone1 or 0,
		constraintInfos.bone2 or 0,
		constraintInfos.forcelimit or 0,
		tobool(constraintInfos.nocollide),
		constraintInfos.deleteEntOnBreak or false
	)

	if not IsValid(constraintEnt) then
		return nil
	end

	enrichConstraintEntityData(constraintEnt)

	return constraintEnt
end

function LIB.NoCollide(ent, parent, constraintInfos)
	constraintInfos = constraintInfos or {}

	local constraintEnt = constraint.NoCollide(
		ent,
		parent,
		constraintInfos.bone1 or 0,
		constraintInfos.bone2 or 0,
		constraintInfos.disableOnRemove or false
	)

	if not IsValid(constraintEnt) then
		return nil
	end

	enrichConstraintEntityData(constraintEnt)

	return constraintEnt
end

function LIB.Axis(ent, parent, constraintInfos)
	constraintInfos = constraintInfos or {}

	local constraintEnt = constraint.Axis(
		ent,
		parent,
		constraintInfos.bone1 or 0,
		constraintInfos.bone2 or 0,
		constraintInfos.lpos1 or CONSTANTS.vecZero,
		constraintInfos.lpos2 or CONSTANTS.vecZero,
		constraintInfos.forcelimit or 0,
		constraintInfos.torquelimit or 0,
		constraintInfos.friction or 0,
		tobool(constraintInfos.nocollide) and 1 or 0,
		constraintInfos.localaxis,
		constraintInfos.dontAddTable or false
	)

	if not IsValid(constraintEnt) then
		return nil
	end

	enrichConstraintEntityData(constraintEnt)

	return constraintEnt
end

function LIB.BallSocket(ent, parent, constraintInfos)
	constraintInfos = constraintInfos or {}

	local constraintEnt = constraint.Ballsocket(
		parent,
		ent,
		constraintInfos.bone1 or 0,
		constraintInfos.bone2 or 0,
		constraintInfos.localpos or CONSTANTS.vecZero,
		constraintInfos.forcelimit or 0,
		constraintInfos.torquelimit or 0,
		tobool(constraintInfos.nocollide) and 1 or 0
	)

	if not IsValid(constraintEnt) then
		return nil
	end

	enrichConstraintEntityData(constraintEnt)

	return constraintEnt
end

function LIB.AdvBallsocket(ent, parent, constraintInfos)
	constraintInfos = constraintInfos or {}

	local constraintEnt = constraint.AdvBallsocket(
		ent,
		parent,
		constraintInfos.bone1 or 0,
		constraintInfos.bone2 or 0,
		constraintInfos.lpos1 or CONSTANTS.vecZero,
		constraintInfos.lpos2 or CONSTANTS.vecZero,
		constraintInfos.forcelimit or 0,
		constraintInfos.torquelimit or 0,
		constraintInfos.xmin or 0,
		constraintInfos.ymin or 0,
		constraintInfos.zmin or 0,
		constraintInfos.xmax or 0,
		constraintInfos.ymax or 0,
		constraintInfos.zmax or 0,
		constraintInfos.xfric or 0,
		constraintInfos.yfric or 0,
		constraintInfos.zfric or 0,
		constraintInfos.onlyrotation or 0,
		tobool(constraintInfos.nocollide) and 1 or 0
	)

	if not IsValid(constraintEnt) then
		return nil
	end

	enrichConstraintEntityData(constraintEnt)

	return constraintEnt
end

function LIB.Keepupright(ent, constraintInfos)
	constraintInfos = constraintInfos or {}

	local constraintEnt = constraint.Keepupright(
		ent,
		constraintInfos.ang or CONSTANTS.angZero,
		constraintInfos.bone1 or 0,
		constraintInfos.angularLimit or 0
	)

	if not IsValid(constraintEnt) then
		return nil
	end

	enrichConstraintEntityData(constraintEnt)

	return constraintEnt
end

function LIB.RemoveAll(ent)
	return constraint.RemoveAll(ent)
end

function LIB.RemoveConstraints(ent, constraintName)
	return constraint.RemoveConstraints(ent, constraintName)
end

function LIB.HasConstraints(ent)
	return constraint.HasConstraints(ent)
end

function LIB.GetAllConstrainedEntities(ent)
	local resultTable = {}
	return constraint.GetAllConstrainedEntities(ent, resultTable)
end

function LIB.GetTable(ent)
	return constraint.GetTable(ent)
end

return true

