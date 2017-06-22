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

zpm.git = { }

function zpm.git.getHash(destination, tag)

    local current = os.getcwd()

    os.chdir(destination)
    
    local hash = os.outputoff("git rev-parse %s", tag)

    os.chdir(current)

    return hash
end

function zpm.git.pull(destination, url, branch)

    local current = os.getcwd()

    os.chdir(destination)
    
    os.executef("git fetch %s --tags --all -q -j 8", url)
    
    if branch then
        os.executef("git checkout -q origin/%s", branch)
    end
   
    os.execute("git submodule update --init --recursive -j 8")

    os.chdir(current)
end

function zpm.git.clone(destination, url, branch)

    local branchStr = ""
    if branch then
        branchStr = string.format(" -b %s ", branch)
    end
    os.executef( "git clone -v --recurse -j8 --progress \"%s\" \"%s\" %s", url, destination, branchStr )
end

function zpm.git.cloneOrPull(destination, url, branch)


    if os.isdir(destination) then

        return zpm.git.pull(destination, url, branch)
    else

        zpm.git.clone(destination, url, branch)
    end
end

function zpm.git.getTags(destination)

    local current = os.getcwd()

    os.chdir(destination)

    local tagStr, errorCode = os.outputof("git show-ref --tags")

    local tags = { }
    if tagStr then
        for _, s in ipairs(tagStr:explode("\n")) do

            if s:len() > 0 then

                local split = zpm.util.split(s, " ")
                local ref, version = split[1], split[2]
                version = version:match("[._-]*([%d+%.]+.*)")
                local ok, semver = pcall(zpm.semver, version)
                if version and ok then
                    table.insert(tags, {
                        version = version,
                        hash = ref,
                        tag = s:match("refs/tags/(.*)"),
                        semver = semver
                    } )
                elseif version then

                    version = version:gsub("_", "%."):match("[._-]*([%d+%.]+.*)")
                    local ok, semver = pcall(zpm.semver, version)
                    if version and ok then
                        table.insert(tags, {
                            version = version,
                            hash = ref,
                            tag = s:match("refs/tags/(.*)"),
                            semver = semver
                        } )
                    else

                        local version, pattern = version:match("(%d+%.%d+%.%d+)%.?(.*)")
                        if version and pattern then
                            version = ("%s+b%s"):format(version, pattern)
                            
                            local ok, semver = pcall(zpm.semver, version)
                            if ok then
                                table.insert(tags, {
                                    version = version,
                                    hash = ref,
                                    tag = s:match("refs/tags/(.*)"),
                                    semver = semver
                                } )
                            end
                        end
                    end
                end
            end
        end

        table.sort(tags, function(t1, t2)
            return bootstrap.semver(t1.version) > bootstrap.semver(t2.version)
        end )
    end

    os.chdir(current)

    return tags
end

function zpm.git.export(from, output, tag)

    local temp = path.join(zpm.loader.temp, ("%s.zip"):format(string.sha1(from)))
    local current = os.getcwd()

    os.chdir(from)

    os.executef("git archive --format=zip --output=\"%s\" %s", temp, tag.tag)

    os.chdir(current)
    
    zip.extract(temp, output)    

    os.remove(temp)
end

function zpm.git.getBranches(from)

    local current = os.getcwd()

    os.chdir(from)

    local output = os.outputof("git branch -r")

    os.chdir(current)

    local branches = { }

    for _, s in ipairs(output:explode("\n")) do
        s = s:gsub("%w*%->.*", "")
        local tag = s:match("origin/(.*)%s*"):match("^%s*(.*%S)") or ""
        table.insert(branches, {
            tag = tag,
            hash = zpm.git.getHash(from, "origin/"..tag)
        })
    end
    return branches
end

function zpm.git.getCommitCount(from, first)

    local current = os.getcwd()

    os.chdir(from)

    local output = os.outputoff("git rev-list %s --count", first)
    os.chdir(current)

    return tonumber(output)
end

function zpm.git.getCommitCountBetween(from, first, second)

    local current = os.getcwd()

    os.chdir(from)

    local output = os.outputoff("git rev-list %s...%s --count", first, second)
    os.chdir(current)

    return tonumber(output)
end

function zpm.git.getCommitAheadBehind(from, first, second)

    local current = os.getcwd()

    os.chdir(from)

    local output = os.outputoff("git rev-list %s...%s --count --left-right", first, second)
    local behind, ahead = output:match("(%d+)%s*(%d+)")

    os.chdir(current)

    return tonumber(ahead), tonumber(behind)
end


function zpm.git.getFileContent(from, file, tag)

    local current = os.getcwd()

    os.chdir(from)

    local output = os.outputoff("git show %s:%s", tag, file)
    local contents = nil
    if not string.startswith(output, "fatal:") then
        contents = output
    end

    os.chdir(current)

    return contents
end