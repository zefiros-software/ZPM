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

zpm.packages = {}

function zpm.packages.load()

    local package = path.join(_MAIN_SCRIPT_DIR, zpm.install.packages.fileName)

    if os.isfile(package) then

        local externDir = zpm.install.getExternDirectory()

        local ok, root = pcall(zpm.packages.loadFile, package, true, zpm.manifest.defaultType, "LOCAL", nil, zpm.packages.root, false)

        if ok then
            zpm.packages.root = root
            if not _OPTIONS["ignore-updates"] then
                zpm.packages.postExtract(zpm.packages.root, true)
            end
        else
            printf(zpm.colors.error .. "Failed to load package '%s' possibly due to an invalid '.package.json':\n%s", package, root)

        end

    end
end