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

zpm.env = { }

function zpm.env.scriptPath()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

function zpm.env.getCacheDirectory()
    local folder = os.getenv("ZPM_CACHE")

    if folder then
        return path.normalize(folder)
    end

    if os.get() == "windows" then
        local temp = path.join(os.getenv("USERPROFILE"), "AppData/Local/Temp/")
        return path.normalize(path.join(temp, "zpm-cache"))
    else

        local home = path.join(os.getenv("HOME"), ".zpm");
        if not os.isdir(home) then
            os.mkdir(home)
        end

        return path.normalize(path.join(home, "zpm-cache"));
    end
end

function zpm.env.getDataDirectory()

    -- Test if there is a User mode install present
    -- if yes, prefer this over the global install

    local osStr = os.get()
    if osStr == "windows" then
        local userInstallPath = path.join(os.getenv("USERPROFILE"), ".zpm");
        if os.isdir(userInstallPath) then
            return userInstallPath;
        else
            return zpm.env.getSharedDataDirectory()
        end

    elseif osStr == "linux" or osStr == "macosx" then
        local userInstallPath = path.join(os.getenv("HOME"), ".zpm");
        if os.isdir(userInstallPath) then
            return userInstallPath;
        else
            return zpm.env.getSharedDataDirectory()
        end
    else
        zpm.assert(false, "Current platform '%s' is currently not supported!", osStr)
    end
end

function zpm.env.getSharedDataDirectory()

    local shared = os.getenv("ZPM_SHARED_DIR")
    if shared ~= "" and shared ~= nil then
        return shared
    end

    local osStr = os.get()

    if osStr == "windows" then
        return os.getenv("ALLUSERSPROFILE")
    elseif osStr == "linux" then
        return "/usr/local/"
    elseif osStr == "macosx" then
        return "/usr/local/"
    else
        zpm.assert(false, "Current platform '%s' is currently not supported!", osStr)
    end

end