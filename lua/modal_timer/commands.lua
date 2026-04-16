local C = {}

function C.register(M)
	vim.api.nvim_create_user_command("AddTimer", function(cmd)
		local args = cmd.fargs
		local hm = args[1]
		local msg = table.concat(args, " ", 2)
		M.add_timer(hm, msg)
	end, { nargs = "+", desc = "modal_timer: add timer (HH:MM message...)" })

	vim.api.nvim_create_user_command("RemoveTimer", function(cmd)
		M.remove_timer(cmd.fargs[1])
	end, { nargs = 1, desc = "modal_timer: remove timer (HH:MM)" })

	vim.api.nvim_create_user_command("ClearTimers", function()
		M.clear_timers()
	end, { nargs = 0, desc = "modal_timer: clear all timers and stop" })

	vim.api.nvim_create_user_command("ListTimers", function()
		M.list_timers()
	end, { nargs = 0, desc = "modal_timer: list timers" })
end

return C
