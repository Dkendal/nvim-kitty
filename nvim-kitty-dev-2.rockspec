rockspec_format = "3.0"
package = "nvim-kitty"
version = "dev-2"
source = {
   url = "git+ssh://git@github.com/Dkendal/nvim-kitty.git"
}
description = {
   summary = "",
   detailed = "",
   homepage = "https://github.com/dkendal/nvim-kitty",
   license = "MIT"
}
build = {
   type = "builtin",
   modules = {},
   copy_directories = {}
}
test_dependencies = {
   "lua == 5.1",
   "busted ~> 2.2.0",
   "typecheck ~> 3.0",
   "luassert ~> 1.9.0",
   "luacov ~> 0.15.0",
   "luacov-multiple ~> 0.6"
}
test = {
   command = "busted",
   flags = {
      "--shuffle",
      "--coverage",
      "--defer-print"
   }
}
