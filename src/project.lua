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

Project = newclass "Project"

function Project:init(loader)

    self.loader = loader
    self.root = Package(loader, nil, {
        repository = _MAIN_SCRIPT_DIR,
        definition = _MAIN_SCRIPT_DIR,
        isRoot = true
    })
    self.solver = Solver(self.loader, self.root)
    self.solution = nil
    self.builder = nil
end

function Project:solve()

    local lock = nil
    if self:hasLockFile() and not zpm.cli.ignoreLock() then
        noticef("Detected a lock file")
        lock = zpm.ser.loadFile(self:getLockFile())
    end

    local cost, solution = self.solver:solve(lock)

    self.solution = solution:extract()
    os.writefile_ifnotequal(json.encode_pretty(solution:extract(true)), self:getLockFile())

    self:extract()

    self.builder = Builder(self.loader, self.solution)
end

function Project:extract()

    local stats = {
        updated = 0
    }
    self:_extractNode(self.solution, "public", stats)
    self:_extractNode(self.solution, "private", stats)

    if stats.updated == 0 then
        noticef("No changes in your dependencies!")
    end
end

function Project:hasLockFile()

    return os.isfile(self:getLockFile())
end

function Project:getLockFile()

    return path.join(_WORKING_DIR, "zpm.lock")
end

function Project:_extractNode(node, access, printStats)

    for _, type in ipairs(self.loader.manifests:getLoadOrder()) do
        local extractDir = self.loader[type]:getExtractDirectory()
        if node[access] and node[access][type] and extractDir then
            if not os.isdir(extractDir) then
                zpm.util.recurseMkdir(extractDir)
                noticef("Creating directory '%s'", extractDir)
            end
            local gitignore = path.join(extractDir, ".gitignore")
            if not os.isfile(gitignore) then
                zpm.util.writeAll(gitignore, "*")
            end

            for _, n in ipairs(node[access][type]) do
                n.location = n.package:getExtractDirectory(extractDir, n)
                if n.package:needsExtraction(extractDir, n) then   
                    if not printStats[type] then
                        printStats[type] = true
                        noticef("Extracting %s to '%s'", type, extractDir)
                    end                  
                    if n.package:extract(extractDir, n) then
                        printStats.updated = printStats.updated + 1
                    end
                end
                local version = n.version
                if not version then
                    version = n.tag
                end

                if version then
                    n.export = n.package:findPackageExport(version)
                end
                
                self:_extractNode(n, "public", printStats)
                self:_extractNode(n, "private", printStats)
            end
        end
    end
end