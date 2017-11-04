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

function zpm.git.hasHash(destination, hash)

    local current = os.getcwd()

    os.chdir(destination)
    
    local out, code = os.outputoff("git cat-file -e %s", hash)
    os.chdir(current)

    return code == 0
end

function zpm.git.hasSubmodules(destination)

    local current = os.getcwd()

    os.chdir(destination)
    
    local out, code = os.outputoff("git ls-files --stage")

    os.chdir(current)

    -- 16000 resolves to a submodule
    return out and out:contains("160000")
end

function zpm.git.setOrigin(destination, url)

    local current = os.getcwd()

    os.chdir(destination)

    local status, errorCode = os.outputof("git remote get-url origin")

    if not status:contains(url) and zpm.util.hasGitUrl(url) then
        os.executef("git remote set-url origin %s", url)
        os.execute("git branch --set-upstream-to origin/master")
    elseif not status:contains(url) then
        os.executef("git remote add origin %s", url)
        os.execute("git branch --set-upstream-to origin/master")
    end

    os.chdir(current)
end

function zpm.git.checkout(destination, hash)

    local current = os.getcwd()

    os.chdir(destination)

    local status, errorCode = os.outputof("git log -1 --format=\"%H\"")

    if not status:contains(hash)then
        os.executef("git checkout -q -f %s", hash)
        os.execute("git submodule update --init --recursive -j 8 --recommend-shallow")
    end

    os.chdir(current)
end

function zpm.git.fetch(destination, url, branch)

    zpm.git.setOrigin(destination, url)

    local current = os.getcwd()

    os.chdir(destination)
        
    os.executef("git fetch -q --all -j 8 --force --prune")
    
    if branch then
        os.executef("git checkout -q origin/%s", branch)
    end
   
    output = os.outputof("git config --file .gitmodules --name-only --get-regexp path")
    if output and output:len() > 0 then
        os.execute("git submodule update --init --recursive -j 32 --recommend-shallow")
    end

    os.chdir(current)
end

function zpm.git.pull(destination)

    local current = os.getcwd()

    os.chdir(destination)
        
    os.executef("git pull")

    os.chdir(current)
end

function zpm.git.reset(destination)

    local current = os.getcwd()

    os.chdir(destination)

    branches = os.outputof("git branch -r")
    if branches:contains("origin/HEAD") then
        if os.outputof("git rev-parse HEAD") ~= os.outputof("git rev-parse origin/HEAD") then
            os.executef("git reset -q --hard origin/HEAD")
        end
    else
        os.executef("git reset -q --hard")
    end

    os.chdir(current)
end

function zpm.git.clone(destination, url, branch)

    local branchStr = ""
    if branch then
        branchStr = string.format(" -b %s ", branch)
    end
    os.executef( "git clone -v --recurse -j8 --progress \"%s\" \"%s\" %s", url, destination, branchStr )
    
    

    local current = os.getcwd()

    os.chdir(destination)

    --os.executef( "git config core.ignoreStat true" )
    
    os.executef( "git config core.fscache true" )

    os.chdir(current)
end

function zpm.git.cloneOrFetch(destination, url, branch)

    if os.isdir(destination) then

        return zpm.git.fetch(destination, url, branch)
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

    zpm.git.archive(from, output, tag, "")
    
    local current = os.getcwd()

    os.chdir(from)
    -- also extract the submodules
    local out, code = os.outputoff("git ls-tree -r %s", tag)
    for _, s in ipairs(out:explode("\n")) do
        -- 160000 is gitlink and thus submodule
        if s:contains("160000") then

            local mode, type, hash, link = s:match("(%d+)%s+(%w+)%s+(%w+)%s+(.+)")
            zpm.git.archive(path.join(from, link), output, hash, link .. "/")
        end
    end

    os.chdir(current)
end

function zpm.git.archive(from, output, tag, prefix)

    local temp = path.join(zpm.loader.temp, ("%s.zip"):format(string.sha1(from .. prefix)))
    local current = os.getcwd()
    os.chdir(from)
    
    os.executef("git archive --format=zip --prefix=\"%s\" --output=\"%s\" %s", prefix, temp, tag)
        
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