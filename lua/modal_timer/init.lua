local Time = require("modal_timer.time")
local Store = require("modal_timer.store")
local Commands = require("modal_timer.commands")

local M = {}

M.opts = {
	times = {},
	messages = { "Time to take a break!" },
	strict = false,
	keymaps = {
		enabled = true,
		start = "<leader>ts",
		stop = "<leader>te",
		status = "<leader>tc",
	},
}

local _running = false
local _sched_timer = nil

local function normalize_messages()
	local times = M.opts.times or {}
	local msgs = M.opts.messages or {}

	if type(msgs) ~= "table" then
		msgs = { tostring(msgs) }
	end
	if #times == 0 then
		M.opts.messages = {}
		return
	end
	if #msgs == 0 then
		msgs = { "Time to take a break!" }
	end
	if #msgs == 1 and #times > 1 then
		local one = msgs[1]
		msgs = {}
		for _ = 1, #times do msgs[#msgs + 1] = one end
	end
	if #msgs ~= #times then
		local first = msgs[1] or "Reminder"
		local new = {}
		for i = 1, #times do
			new[i] = msgs[i] or first
		end
		msgs = new
	end

	M.opts.messages = msgs
end

local function pick_message(i)
	normalize_messages()
	return (M.opts.messages and M.opts.messages[i]) or "Reminder"
end

local function restart_if_active()
	if M.is_active() then M.start() end
end

function M.stop(do_notify)
	_running = false
	if _sched_timer then
		_sched_timer:stop()
		_sched_timer:close()
		_sched_timer = nil
	end
	if do_notify then
		vim.notify("modal_timer: Stopped", vim.log.levels.INFO)
	end
end

function M.start()
	M.stop(false)

	if not M.opts.times or #M.opts.times == 0 then
		vim.notify("modal_timer: no times configured", vim.log.levels.WARN)
		return
	end

	local delay, index = Time.seconds_until_next_time_today(M.opts.times)
	if not delay then
		_running = false
		vim.notify("modal_timer: no more reminders today", vim.log.levels.INFO)
		return
	end

	_running = true
	_sched_timer = vim.loop.new_timer()
	_sched_timer:start(delay * 1000, 0, function()
		local msg = pick_message(index)
		local label = M.opts.times[index]

		vim.schedule(function()
			require("window_reminder").show(msg .. " (" .. label .. ")")
		end)

		-- TODAY-ONLY: arm next one for today; if none remain, we stop with message
		M.start()
	end)

	vim.notify("modal_timer: Started", vim.log.levels.INFO)
end

function M.is_active()
	return _running and _sched_timer ~= nil
end

function M.status()
	vim.notify("modal_timer: " .. (M.is_active() and "ACTIVE" or "NOT ACTIVE"), vim.log.levels.INFO)
end

-- Commands API (persisting)
function M.add_timer(hm, msg)
	if not hm or hm == "" then
		vim.notify("modal_timer: AddTimer requires HH:MM", vim.log.levels.ERROR)
		return
	end
	if not Time.parse_hm(hm) then
		vim.notify("modal_timer: invalid time '" .. hm .. "' (expected HH:MM)", vim.log.levels.ERROR)
		return
	end

	M.opts.times = M.opts.times or {}
	M.opts.messages = M.opts.messages or {}
	normalize_messages()

	for i, t in ipairs(M.opts.times) do
		if t == hm then
			if msg and msg ~= "" then
				M.opts.messages[i] = msg
				Store.save({ times = M.opts.times, messages = M.opts.messages })
			end
			vim.notify("modal_timer: updated " .. hm, vim.log.levels.INFO)
			restart_if_active()
			return
		end
	end

	table.insert(M.opts.times, hm)
	normalize_messages()
	if msg and msg ~= "" then
		M.opts.messages[#M.opts.times] = msg
	end

	Store.save({ times = M.opts.times, messages = M.opts.messages })
	vim.notify("modal_timer: added " .. hm, vim.log.levels.INFO)
	restart_if_active()
end

function M.remove_timer(hm)
	M.opts.times = M.opts.times or {}
	M.opts.messages = M.opts.messages or {}
	normalize_messages()

	for i, t in ipairs(M.opts.times) do
		if t == hm then
			table.remove(M.opts.times, i)
			table.remove(M.opts.messages, i)
			Store.save({ times = M.opts.times, messages = M.opts.messages })
			vim.notify("modal_timer: removed " .. hm, vim.log.levels.INFO)
			if #M.opts.times == 0 then
				M.stop(false)
			else
				restart_if_active()
			end
			return
		end
	end
	vim.notify("modal_timer: time not found: " .. hm, vim.log.levels.WARN)
end

function M.clear_timers()
	M.opts.times = {}
	M.opts.messages = {}
	Store.clear()
	M.stop(false)
	vim.notify("modal_timer: cleared all timers", vim.log.levels.INFO)
end

function M.list_timers()
	normalize_messages()
	if not M.opts.times or #M.opts.times == 0 then
		vim.notify("modal_timer: no timers configured", vim.log.levels.INFO)
		return
	end

	local lines = {}
	for i, t in ipairs(M.opts.times) do
		lines[#lines + 1] = string.format("%2d) %s — %s", i, t, M.opts.messages[i] or "")
	end
	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "modal_timer: timers" })
end

function M.setup(opts)
	-- load persisted state first
	local persisted = Store.load()

	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
	-- merge persisted on top (so runtime persisted list wins)
	M.opts.times = persisted.times or M.opts.times
	M.opts.messages = persisted.messages or M.opts.messages

	normalize_messages()

	-- keymaps
	local km = M.opts.keymaps
	if km and km.enabled then
		local map = function(lhs, rhs, desc)
			if not lhs or lhs == "" then return end
			vim.keymap.set("n", lhs, rhs, { silent = true, noremap = true, desc = desc })
		end
		map(km.start, M.start, "modal_timer: start")
		map(km.stop, function() M.stop(true) end, "modal_timer: stop")
		map(km.status, M.status, "modal_timer: status")
	end

	Commands.register(M)
end

return M
