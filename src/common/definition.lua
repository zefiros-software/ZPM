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

Definition = newclass "Definition"

function Definition:init(loader)

    self.loader = loader

    self.file = path.join(_MAIN_SCRIPT_DIR, "package.yml")
    if not os.isfile(self.file) then
        self.file = path.join(_MAIN_SCRIPT_DIR, ".package.yml")
    end
    self.content = zpm.ser.loadFile(self.file)
end

function Definition:add(name, tpe, options)

    options = iif(options ~= nil, options, {})

    local idx = {tpe}
    if options.development then
        table.insert(idx, 1, "development")
    end
    if options.public then
        table.insert(idx, 1, "public")
    elseif options.private then
        table.insert(idx, 1, "private")
    end

    local version = "*"
    if options.version then
        version = options.version
    end

    local found = false
    local cursor = zpm.util.indexTable(self.content, idx)
    if cursor then
        for i, tab in ipairs(cursor) do
            if tab.name == name then
                warningf('You already have %s \'%s\' in your package file', tpe, name)
                found = true
                break
            end
        end
    end

    if not found then
        zpm.util.insertTable(self.content, idx, {
            name = name,
            version = version,
            preload = iif(options.preload, true, false)
        })
    end
    zpm.util.writeAll(self.file, yaml.encode(self.content))
end
