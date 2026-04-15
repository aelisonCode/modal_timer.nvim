local M = {}

M.opts = {
	-- Daily times (24h) in HH:MM format, e.g. { "09:00", "13:30" }
	times = {},

	-- If 1 message: used for all times.
	-- If same length as times: message[i] is used for times[i].
	messages = { "Time to take a break!" },

	-- If true, mismatched messages/times raises an error.
	-- If false, it warns and uses the first message.
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

	local warn = ("modal_timer: messages (%d) != times (%d); using first message")
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
		vim.notify("modal_timer: no times configured", vim.log.levels.WARN)
		return
	end

	local delay, index = seconds_until_next_time(M.opts.times)
	if not delay then
		vim.notify("modal_timer: no valid reminder times configured (expected HH:MM)", vim.log.levels.ERROR)
		return
	end

	_running = true
	_sched_timer = vim.loop.new_timer()
	_sched_timer:start(delay * 1000, 0, function()
		local msg = pick_message(index)
		local label = M.opts.times[index]

		vim.schedule(function()
			-- Provided by dependency plugin: aelisonCode/modal_reminder.nvim
			require("window_reminder").show(msg .. " (" .. label .. ")")
		end)

		-- Re-arm the one-shot timer for the next scheduled time
		M.start()
	end)
end

function M.is_active()
	return _running and _sched_timer ~= nil
end

function M.status()
	if M.is_active() then
		vim.notify("modal_timer: ACTIVE", vim.log.levels.INFO)
	else
		vim.notify("modal_timer: NOT ACTIVE", vim.log.levels.INFO)
	end
end

function M.setup(opts)
	M.opts = vim.tbl_deep_extend("force", M.opts, opts or {})

	local km = M.opts.keymaps
	if km and km.enabled then
		local map = function(lhs, rhs, desc)
			if not lhs or lhs == "" then return end
			vim.keymap.set("n", lhs, rhs, { silent = true, noremap = true, desc = desc })
		end

		map(km.start, M.start, "modal_timer: start")
		map(km.stop, M.stop, "modal_timer: stop")
		map(km.status, M.status, "modal_timer: status")
	end
end

return M
