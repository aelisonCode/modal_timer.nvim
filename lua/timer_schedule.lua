local M = {}

M.opts = {
	times = {},                      -- Format expected: { "09:00", "13:30" }
	messages = { "Time to take a break!" }, -- 1 message or same length as times
	strict = false,                  -- if true, error on mismatch

	keymaps = {
		enabled = true,
		start = "<leader>ts",
		stop = "<leader>te",
		status = "<leader>tc",
	},
}

local _running = false
local _sched_timer = nil

function M.setup(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})
	local km = M.opts.keymaps
	if km and km.enabled then
		local map = function(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { silent = true, noremap = true, desc = desc })
		end

		map(km.start, function() require("timer_schedule").start() end, "Reminder: start schedule")
		map(km.stop, function() require("timer_schedule").stop() end, "Reminder: stop schedule")
		map(km.status, function() require("timer_schedule").status() end, "Reminder: schedule status")
	end
end

local function parse_hm(hm)
	local h, m = hm:match("^(%d%d):(%d%d)$")
	if not h then return nil end
	h, m = tonumber(h), tonumber(m)
	if h > 23 or m > 59 then return nil end
	return h, m
end

local function pick_message(i)
	local msgs = M.opts.messages or {}
	if #msgs == 0 then
		return "Reminder"
	end
	if #msgs == 1 then
		return msgs[1]
	end
	if #msgs == #M.opts.times then
		return msgs[i]
	end

	local warn = ("window_reminder_schedule: messages (%d) != times (%d); using first message")
	:format(#msgs, #M.opts.times)

	if M.opts.strict then
		error(warn)
	else
		vim.schedule(function()
			vim.notify(warn, vim.log.levels.WARN)
		end)
		return msgs[1]
	end
end

local function seconds_until_next_time(times)
	local now = os.date("*t")
	local now_ts = os.time(now)

	local best = nil
	local best_index = nil

	for i, hm in ipairs(times) do
		local h, m = parse_hm(hm)
		if h then
			local cand = {
				year = now.year,
				month = now.month,
				day = now.day,
				hour = h,
				min = m,
				sec = 0,
			}
			local cand_ts = os.time(cand)
			if cand_ts <= now_ts then
				cand.day = cand.day + 1
				cand_ts = os.time(cand)
			end

			local delta = cand_ts - now_ts
			if not best or delta < best then
				best = delta
				best_index = i
			end
		end
	end

	return best, best_index
end

function M.stop()
	_running = false
	if _sched_timer then
		_sched_timer:stop()
		_sched_timer:close()
		_sched_timer = nil
	end
end

function M.start()
	M.stop()

	if not M.opts.times or #M.opts.times == 0 then
		vim.notify("window_reminder_schedule: no times configured", vim.log.levels.WARN)
		return
	end

	local delay, index = seconds_until_next_time(M.opts.times)
	if not delay then
		vim.notify("No valid reminder times configured (expected HH:MM)", vim.log.levels.ERROR)
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
		M.start()
	end)
end

function M.is_active()
	return _running and _sched_timer ~= nil
end

function M.status()
	if M.is_active() then
		vim.notify("Timer: ACTIVE", vim.log.levels.INFO)
	else
		vim.notify("Timer: NOT ACTIVE", vim.log.levels.INFO)
	end
end

return M
