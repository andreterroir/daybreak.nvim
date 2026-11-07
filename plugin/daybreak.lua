-- Plugin managers source this file before applying setup options.
if vim.g.loaded_daybreak then
  return
end
vim.g.loaded_daybreak = 1

vim.schedule(function()
  if not vim.g.daybreak_did_setup then
    require('daybreak').setup()
  end
end)
