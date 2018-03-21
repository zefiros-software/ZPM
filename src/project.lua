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
        if not zpm.cli.run() then
            noticef("Detected a lock file")
        end
        self.oldLock = zpm.ser.loadFile(self:getLockFile())
    end

    local cost, solution = self.solver:solve(self.oldLock)
    if solution then
        self.solution = solution:extract()
        self.lock = solution:extract(true)

        self:_writeLock()

        self:bake()

        if zpm.meta.mayExtract then
            self:extract()
        end

        self.builder = Builder(self.loader, self.solution)
        
        if not zpm.cli.run() then
            self:printDiff()
        end
    else
        errorf("Failed to find a configuration satisfying all constraints!")
    end
end

function Project:printDiff()

    self:_printDiff(table.deepcopy(iif(self.oldLock, self.oldLock, {})), table.deepcopy(iif(self.lock, self.lock, {})))
end

function Project:bake()

    -- Load the settings from each node
    self.solution:iterateAccessibilityDFS(function(access, type, node, parent, index)

        if parent and parent.optionalIndices[parent] then
            return false
        end

        if node.name and node.settings then
            for setting, value in pairs(node.settings) do
                if self.loader.settings({type, node.name, node.tag, setting}) then
                    self.loader.settings:add({type, node.name, node.tag, setting, "values"}, value)
                end
            end
        end        
        
        if node.optionals then
            for type, pkgs in pairs(node.optionals) do
                for _, pkg in ipairs(pkgs) do
                    if pkg.settings then
                        local closed = zpm.util.indexTable(self.solution.tree.closed.public, {type,pkg.name}) 
                        print(table.tostring(closed), pkg.settings)
                        if closed and premake.checkVersion(closed.version, pkg.versionRequirement) then
                            
                            for setting, value in pairs(pkg.settings) do
                                print(type, pkg.name, closed.version, setting)
                                if self.loader.settings({type, pkg.name, closed.version, setting}) then
                                    self.loader.settings:add({type, pkg.name, closed.version, setting, "values"}, value)
                                end
                            end
                        end     
                    end
                end
            end
        end

        return true
    end, true)
    
    -- load the modules
    
    for _, gtype in ipairs(self.loader.manifests:getLoadOrder()) do
        self.solution:iterateAccessibilityDFS(function(access, type, node)
        
            if gtype == type and node.package then
                node.package:onLoad(node.version, node.tag)
            end

            return true
        end, true)
    end
end

function Project:extract()

    local stats = {
        updated = 0
    }
    
    self.solution:iterateAccessibilityDFS(function(access, type, node)
        local extractDir = self.loader[type]:getExtractDirectory()
        if extractDir then   
            node.location = node.package:getExtractDirectory(extractDir, node)
            if node.package:needsExtraction(extractDir, node) then   
            
                if not os.isdir(extractDir) then
                    zpm.util.recurseMkdir(extractDir)
                    noticef("Creating directory '%s'", extractDir)
                end
                local gitignore = path.join(extractDir, ".gitignore")
                if not os.isfile(gitignore) then
                    zpm.util.writeAll(gitignore, "*")
                end 

                if not stats[type] then
                    stats[type] = true
                    noticef("Extracting %s to '%s'", type, extractDir)
                end                         

                if node.package:extract(extractDir, node) then
                    stats.updated = stats.updated + 1
                end
            end
        end

        local version = node.version
        if not version then
            version = node.tag
        end

        if version then
            node.export = node.package:findPackageExport(version, node.hash)
        end
            
        return true
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

    if not table.isempty(self.lock) then
        os.writefile_ifnotequal(json.encode_pretty(self.lock), self:getLockFile())
    end
end

function Project:_printDiff(lock, solution, depth)
    depth = iif(depth, depth, 0)
    local dstr = string.rep("      ", depth)
    
    local printedTypes = {
        public = {},
        private = {}
    }
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

                    if not printedTypes[access][type] then
                        printf("%%{blue bright}%s%s - %s:", dstr, iif(access=="private", "X", "O"), string.capitalized(type))
                        printedTypes[access][type] = true
                    end

                    if found then
                        if found.hash == pkg.hash then
                            printf("%%{yellow bright}%s\\_ %s (%s@%s)", dstr, pkg.name, pkg.tag, pkg.hash:sub(0,5) )
                        else
                            printf("%%{green bright}%s\\_ %s (%s@%s) => (%s@%s)", dstr, found.name, found.tag, found.hash:sub(0,5), pkg.tag, pkg.hash:sub(0,5) )
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

                    if not printedTypes[access][type] then
                        printf("%%{blue bright}%s%s - %s:", dstr, iif(access=="private", "X", "O"), string.capitalized(type))
                        printedTypes[access][type] = true
                    end

                    printf("%%{red bright}%s\\_ %s (%s@%s) Removed", dstr, pkg.name, pkg.tag, pkg.hash:sub(0,5) )                  
                end
            end
        end
    end
end