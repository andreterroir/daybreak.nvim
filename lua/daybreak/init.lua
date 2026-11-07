local M = {}

-- The implementation lives in autoload/daybreak.vim so Vim can share it.
function M.setup(opts)
  vim.fn['daybreak#setup'](opts or {})
end

return M
