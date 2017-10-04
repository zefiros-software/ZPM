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

Tree = newclass "Tree"

function Tree:init(loader, tree)

    self.loader = loader
    self.tree = tree
    
    -- store all node information in the closed public table
    self:iterateAccessibilityDFS(function(access, type, node)

        if access == "public" then
            self.tree.closed.public[type][node.name].node = node
        end
        return true
    end)
    
    -- prepare nodes
    self:iterateAccessibilityDFS(function(access, type, node)

        node.optionalIndices = {}
        return true
    end, true)

    -- inject the node in the dependencies
    self:iterateAccessibilityDFS(function(access, type, node)
        
        if node.optionals then
            for type, pkgs in pairs(node.optionals) do
                for _, pkg in ipairs(pkgs) do
                    local closed = zpm.util.indexTable(self.tree.closed.public, {type,pkg.name}) 
                    if closed and premake.checkVersion(closed.version, pkg.versionRequirement) then
                        if not node.public then
                            node.public = {}
                        end
                        if not node.public[type] then
                            node.public[type] = {}
                        end
                        local ix = #node.public[type] + 1
                        node.public[type][ix] = self.tree.closed.public[type][pkg.name].node
                        zpm.util.setTable(node.optionalIndices, {type, ix}, true)
                        pkg.exists = true
                        
                        return false
                    end
                end
            end
        end
        return true
    end)
end


function Tree:iterateAccessibilityDFS(nodFunc, useRoot)

    useRoot = iif(useRoot == nil, false, useRoot)
    self:_walkAccessibilityDFS(self.tree, "public", nodFunc)
    self:_walkAccessibilityDFS(self.tree, "private", nodFunc)

    if useRoot then
        nodFunc("public", self.tree.type, self.tree)
    end
end

function Tree:iterateDFS(nodFunc, useRoot)

    useRoot = iif(useRoot == nil, false, useRoot)
    self:_walkDependencyDFS(self.tree, nodFunc)

    if useRoot then
        nodFunc(self.tree)
    end
end

function Tree:_walkDependencyDFS(cursor, nodFunc, ntype, parent, index)

    for _, access in ipairs({"private", "public"}) do
        for _, type in ipairs(self.loader.manifests:getLoadOrder()) do
            local pkgs = zpm.util.indexTable(cursor,{access, type})
            if pkgs then            
                table.sort(pkgs, function(a,b) return a.name < b.name end)
                for i, pkg in ipairs(pkgs) do
                    self:_walkDependencyDFS(pkg, nodFunc, type, cursor, i)
                end
            end
        end
    end

    nodFunc(cursor, ntype, parent, index)
end

function Tree:_walkAccessibilityDFS(node, access, nodFunc)
    
    for _, type in ipairs(self.loader.manifests:getLoadOrder()) do
        if node[access] and node[access][type] then        
        
            table.sort(node[access][type], function(a,b) return a.name < b.name end)
            for i, n in ipairs(node[access][type]) do

                if nodFunc(access, type, n, node, i) then
                            
                    self:_walkAccessibilityDFS(n, "public", nodFunc)
                    self:_walkAccessibilityDFS(n, "private", nodFunc)
                end
            end
        end
    end
end