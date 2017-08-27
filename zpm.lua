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

if not zpm then
    zpm = {}
    zpm.meta = {
        workspace = "",
        group = "",
        project = "",
        exporting = false,
        buiding = false,
        package = nil
    }
    zpm._VERSION = "2.0.0"
end

dofile "extern/load.lua"
dofile "src/load.lua"

function zpm.onLoad()
    
    if not zpm._mayLoad() then
        return
    end
    
    zpm.loader = Loader()
    zpm.loader.install:checkVersion()
    zpm.loader.registries:load()
    zpm.loader.manifests:load()
    zpm.loader:solve()
end

function zpm._mayLoad()

    return not zpm.cli.showVersion() and
           not zpm.cli.show()
end

return zpm