--[[ @cond ___LICENSE___
-- Copyright (c) 2017 Zefiros Software.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--
-- @endcond
--]]

dofile "loader.lua"
dofile "config.lua"
dofile "install.lua"
dofile "packages.lua"
dofile "modules.lua"
dofile "libraries.lua"
dofile "project.lua"
dofile "solution.lua"
dofile "solver.lua"

dofile "registry/registries.lua"
dofile "registry/registry.lua"

dofile "manifest/package.lua"
dofile "manifest/module.lua"

dofile "common/validate.lua"
dofile "common/prioqueue.lua"
dofile "common/stack.lua"
dofile "common/queue.lua"
dofile "common/env.lua"
dofile "common/ser.lua"
dofile "common/options.lua"
dofile "common/git.lua"
dofile "common/premake.lua"
dofile "common/bootstrap.lua"
dofile "common/github.lua"
dofile "common/http.lua"
dofile "common/util.lua"

dofile "cli/cli.lua"
dofile "cli/config.lua"
dofile "cli/show.lua"
dofile "cli/install.lua"
dofile "cli/github.lua"

dofile "manifest/manifest.lua"
dofile "manifest/manifests.lua"