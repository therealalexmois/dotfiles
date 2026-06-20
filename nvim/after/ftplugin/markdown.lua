-- Soft wrap для markdown: строки в файле не меняются, переносятся только визуально.
-- Глобальный `wrap = false` (см. lua/plugins/astrocore.lua) остаётся в силе для остальных типов.
vim.opt_local.wrap = true -- визуальный перенос длинных строк
vim.opt_local.linebreak = true -- перенос по словам, а не по символам
vim.opt_local.breakindent = true -- сохранять отступ перенесённой строки

-- Навигация по визуальным строкам, а не по строкам файла (важно при длинных параграфах).
local opts = { buffer = true, silent = true }
vim.keymap.set({ "n", "x" }, "j", "gj", opts)
vim.keymap.set({ "n", "x" }, "k", "gk", opts)
vim.keymap.set({ "n", "x" }, "0", "g0", opts)
vim.keymap.set({ "n", "x" }, "$", "g$", opts)
