local S = {}

local function path()
	return vim.fn.stdpath("data") .. "/modal_timer.json"
end

function S.load()
	local p = path()
	local ok, data = pcall(vim.fn.readfile, p)
	if not ok then
		return nil
	end

	local text = table.concat(data, "\n")
	if text == "" then
		return nil
	end

	local ok2, decoded = pcall(vim.json.decode, text)
	if not ok2 or type(decoded) ~= "table" then
		return nil
	end

	decoded.times = decoded.times or {}
	decoded.messages = decoded.messages or {}
	return decoded
end

function S.save(state)
	local p = path()
	local encoded = vim.json.encode({
		times = state.times or {},
		messages = state.messages or {},
	})
	vim.fn.writefile({ encoded }, p)
end

function S.clear()
	S.save({ times = {}, messages = {} })
end

return S
