-- Plugin managers source this file before applying setup options.
vim.schedule(function()
	local daybreak = require('daybreak')
	if not daybreak.did_setup then
		daybreak.setup()
	end
end)
