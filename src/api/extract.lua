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

zpm.api.extract = {
    export = {},
    global = {}
}

function zpm.api.extract.default(env, package)

    env["os"]["execute"] = os.execute
    env["os"]["executef"] = os.executef
    env["os"]["output"] = os.output
    env["os"]["outputf"] = os.outputf
end

function zpm.api.extract.export.extractdir(package)

    return function(targets, prefix)
        prefix = prefix or "./"

        if type(targets) ~= "table" then
            targets = {targets}
        end
    
        for i, target in ipairs(targets) do
            local fromPath = path.join( package.package:getRepository(), target )
            local targetPath = path.join( package.location, prefix, target )

            
            noticef("   Copying '%s' to '%s'", target, path.join(prefix, target))
            if os.ishost("windows") then
                os.outputoff("robocopy \"%s\" \"%s\" * /E /xd \".git\" /MT /J /FFT /XO", fromPath, targetPath)
            else
                os.outputoff("rsync -r --exclude=\"%s/.git\" \"%s/*\" \"%s\"", fromPath, fromPath, targetPath)
            end
        end
    end
end

function zpm.api.extract.export.setting(package)

    return zpm.setting
end