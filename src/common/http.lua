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

function Http:init(loader)

    self.loader = loader
end

function Http:get(url, headers, extra)

    headers = iif(headers == nil, { }, headers)
    
    local response, result, code = http.get(url, { 
        headers = headers
    })

    return response
end

function Http:download(url, outFile, headers)
    
    local response, code = http.download(url, outFile, { 
        headers = headers
    })
   
    return response
end

function Http:downloadFromArchive(url, pattern)

    if url:contains(".zip") then
        return self:downloadFromZip(url, pattern)
    end
    return self:downloadFromTarGz(url, pattern)
end

function Http:downloadFromZipTo(url, destination, pattern)

    pattern = iif(pattern == nil, "*", pattern)
    local zipFile = path.join(self.loader.temp, os.uuid() .. ".zip")

    self:download(url, zipFile)
    zip.extract(zipFile, destination)
    
    return os.matchfiles(path.join(destination, pattern))
end

function Http:downloadFromTarGzTo(url, destination, pattern)

    pattern = iif(pattern == nil, "*", pattern)
    local zipFile = path.join(self.loader.temp, os.uuid() .. ".tar.gz")

    self:download(url, zipFile)

    os.executef("tar xzf %s -C %s", zipFile, destination)
    return os.matchfiles(path.join(destination, pattern))
end

function Http:downloadFromZip(url, pattern)

    local dest = path.join(self.loader.temp, os.uuid())
    zpm.assert(os.mkdir(dest), "Failed to create temporary directory '%s'!", dest)
    return self:downloadFromZipTo(url, dest, pattern)
end

function Http:downloadFromTarGz(url, pattern)

    local dest = path.join(self.loader.temp, os.uuid())
    zpm.assert(os.mkdir(dest), "Failed to create temporary directory '%s'!", dest)
    return self:downloadFromTarGzTo(url, dest, pattern)
end
