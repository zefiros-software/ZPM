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
    
    local response, result, code = http.get(url, { 
        headers = self:_convertHeaders(headers)
    })

    return response
end

function Http:download(url, outFile, headers, showProgress)
    
    local mayWrite = true
    function progress(total, current)
        local ratio = current / total;
        ratio = math.min(math.max(ratio, 0), 1);
        local percent = math.floor(ratio * 100);
        if mayWrite then
            io.write("\rDownload progress (" .. percent .. "%/100%)")
        end
        if percent == 100.0 and mayWrite then
            io.write("\n")
            mayWrite = false
        end
    end
    local response, code = http.download(url, outFile, { 
        headers = self:_convertHeaders(headers),
        progress = iif(showProgress, progress, nil)
    })
   
    return response
end

function Http:downloadFromArchive(url, pattern, iszip)

    pattern = iif(pattern == nil or type(pattern) == "boolean", false, pattern)

    if url:contains(".zip") or iszip then
        return self:downloadFromZip(url, pattern)
    end
    return self:downloadFromTarGz(url, pattern)
end

function Http:downloadFromZipTo(url, destination, pattern)

    pattern = iif(pattern == nil or type(pattern) == "boolean", "*", pattern)
    destination = iif(destination == nil or type(destination) == "boolean", path.join(self.loader.temp, os.uuid()), destination)
    local zipFile = path.join(self.loader.temp, os.uuid() .. ".zip")

    self:download(url, zipFile)
    zip.extract(zipFile, destination)
    
    if pattern then
        return os.matchfiles(path.join(destination, pattern))
    else
        return destination
    end
end

function Http:downloadFromTarGzTo(url, destination, pattern)

    pattern = iif(pattern == nil or type(pattern) == "boolean", "*", pattern)
    local zipFile = path.join(self.loader.temp, os.uuid() .. ".tar.gz")

    self:download(url, zipFile)

    os.executef("tar xzf %s -C %s", zipFile, destination)
    
    if pattern then
        return os.matchfiles(path.join(destination, pattern))
    else
        return destination
    end
end

function Http:downloadFromZip(url, pattern)

    pattern = iif(pattern == nil or type(pattern) == "boolean", false, pattern)

    local dest = path.join(self.loader.temp, os.uuid())
    zpm.assert(os.mkdir(dest), "Failed to create temporary directory '%s'!", dest)
    return self:downloadFromZipTo(url, dest, pattern)
end

function Http:downloadFromTarGz(url, pattern)

    local dest = path.join(self.loader.temp, os.uuid())
    zpm.assert(os.mkdir(dest), "Failed to create temporary directory '%s'!", dest)
    return self:downloadFromTarGzTo(url, dest, pattern)
end

function Http:_convertHeaders(headers)

    headers = iif(headers == nil, { }, headers)

    if not zpm.util.isArray(t) then
        local nheaders = {}
        for k, v in pairs(headers) do
            table.insert(nheaders, string.format("%s: %s", k, v))
        end

        return nheaders
    end

    return headers
end