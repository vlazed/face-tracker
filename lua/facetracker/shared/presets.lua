local ROOT = "facetracker/presets"

local function restoreDirectory()
	if
		file.Exists(ROOT, "DATA")
		and file.Exists(ROOT .. "/" .. "facs.txt", "DATA")
		and file.Exists(ROOT .. "/" .. "hwm.txt", "DATA")
		and file.Exists(ROOT .. "/" .. "arkit.txt", "DATA")
	then
		return
	end

	local dataStatic = "data_static/" .. ROOT
	---@param files string[]
	---@param directory string?
	local function writePath(files, directory)
		directory = directory or ""
		for _, filePath in ipairs(files) do
			local fileDirectory = ROOT .. "/" .. directory .. "/"
			local path = fileDirectory .. filePath
			local staticPath = dataStatic .. "/" .. directory .. "/" .. filePath
			if not file.Exists(fileDirectory, "DATA") then
				file.CreateDir(fileDirectory)
			end
			file.Write(path, file.Read(staticPath, "GAME") or "")
		end
	end

	file.CreateDir(ROOT)
	---@param files string[]
	---@param folders string[]
	---@param directory string?
	local function recurseFolders(files, folders, directory)
		directory = directory or ""
		if files then
			writePath(files, directory)
		end
		if #folders > 0 then
			for _, folder in ipairs(folders) do
				local path = dataStatic .. "/" .. folder .. "/*"
				local subfiles, subfolders = file.Find(path, "GAME")
				if subfiles or subfolders then
					recurseFolders(subfiles, subfolders, folder)
				end
			end
		end
	end

	local files, folders = file.Find(dataStatic .. "/*", "GAME")
	if files and folders then
		recurseFolders(files, folders)
	end

	print("Face Tracker: Restored presets directory in data folder")
end

restoreDirectory()

concommand.Add("facetracker_refresh", function(ply, cmd, args, argStr)
	restoreDirectory()
end)
