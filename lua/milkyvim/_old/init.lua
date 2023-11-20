require("milkyvim.utils").file.loadAll("milkyvim/plugins")
require("milkyvim.plugins.lsp")

if require("nixCats").debug then
  require("milkyvim.plugins.debug")
end
