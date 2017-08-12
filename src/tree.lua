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

function Tree:_walkDependencyDFS(cursor, nodFunc, ntype)

    for _, access in ipairs({"private", "public"}) do
        for _, type in ipairs(self.loader.manifests:getLoadOrder()) do
            local pkgs = zpm.util.indexTable(cursor,{access, type})
            if pkgs then            
                table.sort(pkgs, function(a,b) return a.name < b.name end)
                for _, pkg in ipairs(pkgs) do
                    self:_walkDependencyDFS(pkg, nodFunc, type)
                end
            end
        end
    end

    nodFunc(cursor, ntype)
end

function Tree:_walkAccessibilityDFS(node, access, nodFunc)
    
    for _, type in ipairs(self.loader.manifests:getLoadOrder()) do
        if node[access] and node[access][type] then        
        
            table.sort(node[access][type], function(a,b) return a.name < b.name end)
            for _, n in ipairs(node[access][type]) do

                if nodFunc(access, type, n) then
                            
                    self:_walkAccessibilityDFS(n, "public", nodFunc)
                    self:_walkAccessibilityDFS(n, "private", nodFunc)
                end
            end
        end
    end
end