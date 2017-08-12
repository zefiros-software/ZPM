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
        repository = "./",
        definition = "./",
        isRoot = true
    })
    self.solver = Solver(self.loader, self.root)
    self.solution = nil
    self.lock = nil
    self.builder = nil
    self.oldLock = nil
end

function Project:solve()

    if self:hasLockFile() and not zpm.cli.ignoreLock() then
        noticef("Detected a lock file")
        self.oldLock = zpm.ser.loadFile(self:getLockFile())
    end

    local cost, solution = self.solver:solve(self.oldLock)

    if solution then
        self.solution = solution:extract()
        self.lock = solution:extract(true)

        self:_writeLock()

        self:bake()
        self:extract()

        self.builder = Builder(self.loader, self.solution)

        self:printDiff()
    else
        errorf("Failed to find a configuration satisfying all constraints!")
    end
end

function Project:printDiff()

    self:_printDiff(table.deepcopy(iif(self.oldLock, self.oldLock, {})), table.deepcopy(iif(self.lock, self.lock, {})))
end

function Project:bake()

    -- store all node information in the closed public table
    self.solution:iterateAccessibilityDFS(function(access, type, node)
        
        if access == "public" then
            self.solution.tree.closed.public[type][node.name].node = node
        end
        return true
    end)

    -- inject the node in the dependencies
    self.solution:iterateAccessibilityDFS(function(access, type, node)
        
        if node.optionals then
            for type, pkgs in pairs(node.optionals) do
                for _, pkg in ipairs(pkgs) do
                    if zpm.util.indexTable(self.solution.tree.closed.public, {type,pkg.name}) then
                        if not node.public then
                            node.public = {}
                        end
                        if not node.public[type] then
                            node.public[type] = {}
                        end
                        table.insert(node.public[type], self.solution.tree.closed.public[type][pkg.name].node)
                        pkg.exists = true
                    end
                end
            end
        end
        return true
    end)

    -- Load the settings from each node
    self.solution:iterateAccessibilityDFS(function(access, type, node)

        if node.name and node.settings then
            for setting, value in pairs(node.settings) do
                if self.loader.settings({type, node.name, node.hash, setting}) then
                    self.loader.settings:add({type, node.name, node.hash, setting, "values"}, value)
                end
            end
        end

        return true
    end, true)
end

function Project:extract()

    local stats = {
        updated = 0
    }
    
    self.solution:iterateAccessibilityDFS(function(access, type, node)
    
        local extractDir = self.loader[type]:getExtractDirectory()
        if extractDir then
            if not os.isdir(extractDir) then
                zpm.util.recurseMkdir(extractDir)
                noticef("Creating directory '%s'", extractDir)
            end
            local gitignore = path.join(extractDir, ".gitignore")
            if not os.isfile(gitignore) then
                zpm.util.writeAll(gitignore, "*")
            end    

            node.location = node.package:getExtractDirectory(extractDir, node)
            if node.package:needsExtraction(extractDir, node) then   
                if not stats[type] then
                    stats[type] = true
                    noticef("Extracting %s to '%s'", type, extractDir)
                end                  
                if node.package:extract(extractDir, node) then
                    stats.updated = stats.updated + 1
                end
            end
            local version = node.version
            if not version then
                version = node.tag
            end

            if version then
                node.export = node.package:findPackageExport(version)
            end
            
            return true
        end

        return false
    end)

    --if stats.updated == 0 then
        --noticef("No changes in your dependencies!")
    --end
end

function Project:hasLockFile()

    return os.isfile(self:getLockFile())
end

function Project:getLockFile()

    return path.join(_WORKING_DIR, "zpm.lock")
end

function Project:_writeLock()

    print(table.tostring(self.lock.closed, 3))
    if not table.isempty(self.lock) then
        os.writefile_ifnotequal(json.encode_pretty(self.lock), self:getLockFile())
    end
end

function Project:_printDiff(lock, solution, depth)
    depth = iif(depth, depth, 0)
    local dstr = string.rep("      ", depth)

    local foundPkgs = {}
    for _, access in ipairs({"public", "private"}) do
        if solution[access] then
            for type, packages in pairs(solution[access]) do
            
                for _, pkg in ipairs(packages) do
                    local oldPackages = zpm.util.indexTable(lock, {access, type})
                    local found = nil
                    local index = nil
                    if oldPackages then
                        for i, old in pairs(oldPackages) do
                            if pkg.name == old.name then
                                found = old
                                index = i
                                table.insert(foundPkgs, pkg.name)
                                break
                            end
                        end
                    end

                    pkg.hash = iif(pkg.hash, pkg.hash, "")

                    if found then
                        if found.hash == pkg.hash then
                            printf("%%{yellow bright}%s\\_ %s (%s@%s)", dstr, pkg.name, pkg.tag, pkg.hash:sub(0,5) )
                        else
                            printf("%%{yellow green}%s\\_ %s (%s@%s) => (%s@%s)", dstr, found.name, found.tag, found.hash:sub(0,5), pkg.tag, pkg.hash:sub(0,5) )
                        end

                        self:_printDiff(table.deepcopy(found), table.deepcopy(pkg), depth + 1)

                        lock[access][type][index] = nil
                    else
                        printf("%%{green bright}%s\\_ %s (%s@%s) Added", dstr, pkg.name, pkg.tag, pkg.hash:sub(0,5) )        
                         
                        self:_printDiff({}, table.deepcopy(pkg), depth + 1)               
                    end
                end
            end
        end
    end

    for _, access in ipairs({"public", "private"}) do
        if lock[access] then
            for type, packages in pairs(lock[access]) do
                for _, pkg in ipairs(packages) do

                    printf("%%{red bright}%s\\_ %s (%s@%s) Removed", dstr, pkg.name, pkg.tag, pkg.hash:sub(0,5) )                  
                end
            end
        end
    end
end