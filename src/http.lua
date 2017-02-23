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

Http = newclass "Http"

local function _scriptPath()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end

function Http:init(loader)
    self.loader = loader
    self.location = iif(os.is("windows"), path.join( _scriptPath(), "../bin/curl.exe" ), "curl")
end

function Http:get(url, headers, extra)
    headers = iif(headers == nil, { }, headers)
    extra = iif(extra == nil, "", extra)
    local headerStr = ""
    for header, value in pairs(headers) do
        headerStr = headerStr ..(" -H \"%s: %s\""):format(header, value)
    end
    local response, code = os.outputoff("%s -s -L %s %s %s", self.location, headerStr, url, extra)
    return response
end

function Http:download(url, outFile, headers)
    return self:get(url, headers, ("--output %s"):format(outFile) )
end