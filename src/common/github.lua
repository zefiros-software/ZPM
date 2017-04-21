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

Github = newclass "Github"

local function _getAssetsVersion(str)

    local verStr = string.match(str, ".*(%d+%.%d+%.%d+.*)")
    return zpm.semver(verStr)
end

function Github:init(loader)

    self.loader = loader
end

function Github:get(url)

    local token = self:_getToken()
    if token then
        token = { Authorization = "token " .. token }
    end
    return self.loader.http:get(url, token)
end

function Github:getUrl(prefix, organisation, repository, resource)

    local url = self.loader.config("github.apiHost") .. prefix .. "/" .. organisation .. "/" .. repository

    if resource then
        url = url .. "/" .. resource
    end

    return self:get(url)
end

function Github:getReleases(organisation, repository, pattern)
    pattern = iif(pattern ~= nil, pattern, ".*")
    local response = json.decode(self:getUrl("repos", organisation, repository, "releases"))

    local releases = { }
    table.foreachi(response, function(value)

        local ok, vers = pcall(_getAssetsVersion, value["tag_name"])
        if ok then

            local assetTab = { }
            table.foreachi(value["assets"], function(asset)
                if asset.name:match(pattern) then
                    table.insert(assetTab, {
                        name = asset["name"],
                        url = asset["browser_download_url"]
                    } )
                end
            end )

            table.insert(releases, {
                version = vers,
                assets = assetTab
            } )
        end
    end )

    table.sort(releases, function(t1, t2) return t1.version > t2.version end)
    return releases
end

function Github:_getToken()
    local gh = os.getenv("GH_TOKEN")
    if gh then
        return gh
    end

    gh = _OPTIONS["github-token"]
    if gh then
        return gh
    end
    local token = self.loader.config("github.token")
    return iif(token and token:len() > 0, token, nil)
end