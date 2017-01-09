--[[ @cond ___LICENSE___
-- Copyright (c) 2016 Koen Visscher, Paul Visscher and individual contributors.
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

-- GitHub 
zpm.GitHub = { }
zpm.GitHub.host = zpm.config.GitHub.host
zpm.GitHub.apiHost = zpm.config.GitHub.apiHost
zpm.GitHub.token = zpm.config.GitHub.token

if os.getenv("GH_TOKEN") ~= nil then
    zpm.GitHub.token = os.getenv("GH_TOKEN")
end

if _OPTIONS["github-token"] ~= nil then
    zpm.GitHub.token = _OPTIONS["github-token"]
end

function zpm.GitHub.latestCommit(vendor, name)
    local token = zpm.GitHub.token
    if token ~= nil and token ~= false then
        token = "Authorization: token " .. token
    end
    local resp = zpm.wget.get(string.format("https://api.github.com/repos/%s/%s/git/refs/heads/master", vendor, name), token)
    return zpm.JSON:decode(resp)
end

function zpm.GitHub.semanticCompare(t1, t2)
    return t1.version > t2.version
end

function zpm.GitHub.get(url)
    local token = zpm.GitHub.token
    if token ~= nil and token ~= false then
        token = "Authorization: token " .. token
    end
    print(url)
    return zpm.wget.get(url, token)
end

function zpm.GitHub.getUrl(prefix, organisation, repository, resource)
    local url = zpm.GitHub.apiHost .. prefix .. "/" .. organisation .. "/" .. repository

    if resource then
        url = url .. "/" .. resource
    end

    return url
end

function zpm.GitHub.getAssets(organisation, repository)
    local response = zpm.JSON:decode(zpm.GitHub.get(zpm.GitHub.getUrl("repos", organisation, repository, "releases")))

    local releases = { }
    for _, value in ipairs(response) do

        local ok, vers = pcall(zpm.GitHub.GetAssetsVersion, value["tag_name"])
        if ok then

            local assetTab = { }
            for _, asset in ipairs(value["assets"]) do
                table.insert(assetTab, {
                    name = asset["name"],
                    url = asset["browser_download_url"]
                } )
            end

            table.insert(releases, {
                version = vers,
                assets = assetTab
            } )
        end
    end

    table.sort(releases, zpm.GitHub.semanticCompare)
    return releases
end

function zpm.GitHub.latestAssetMatch(organisation, repository, pattern)

    local releases = zpm.GitHub.getAssets(organisation, repository)

    for _, assets in ipairs(releases) do

        for _, asset in ipairs(assets.assets) do
            local assetMatch = asset.name:match(pattern)

            if assetMatch ~= nil then
                return asset, assets.version
            end

        end

    end

    return nil
end

function zpm.GitHub.latestAssetMatches(organisation, repository, pattern)

    local releases = zpm.GitHub.getAssets(organisation, repository)

    local values = { }

    for _, assets in pairs(releases) do

        for _, asset in pairs(assets.assets) do
            local assetMatch = asset.name:match(pattern)

            if assetMatch ~= nil then
                table.insert(values, {
                    name = asset.name,
                    version = assets.version,
                    url = asset.url
                } )
            end

        end

    end

    return values
end

function zpm.GitHub.GetAssetsVersion(str)

    local verStr = string.match(str, ".*(%d+%.%d+%.%d+.*)")
    return zpm.semver(verStr)

end

newoption {
    trigger = "github-token",
    value = "token",
    description = "Uses the given GitHub token"
}