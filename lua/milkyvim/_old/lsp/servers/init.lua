local Utils = require("milkyvim.utils")
Utils.file.loadAll("milkyvim.plugins.lsp.servers")

----------
--* NIX
----------
require("lspconfig").nil_ls.setup({})
