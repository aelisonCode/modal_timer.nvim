local T = {}

function T.parse_hm(hm)
	local h, m = hm:match("^(%d%d):(%d%d)$")
	if not h then return nil end
	h, m = tonumber(h), tonumber(m)
	if h > 23 or m > 59 then return nil end
	return h, m
end

function T.seconds_until_next_time_today(times)
	local now = os.date("*t")
	local now_ts = os.time(now)

	local best, best_index = nil, nil

	for i, hm in ipairs(times or {}) do
		local h, m = T.parse_hm(hm)
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

			if cand_ts > now_ts then
				local delta = cand_ts - now_ts
				if not best or delta < best then
					best = delta
					best_index = i
				end
			end
		end
	end

	return best, best_index
end

return T
