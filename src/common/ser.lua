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

zpm.ser = { }

function zpm.ser.loadFile(file, python)
    if not python then
        python = zpm.loader.python
    end
    
    local json = {}
    if os.isfile(file) then
        if zpm.ser.isYAML(file) then
            local temp = path.join(zpm.env.getTempDirectory(), file:sha1())
            if os.isfile(temp) and os.stat(temp).mtime > os.stat(file).mtime then
                json = zpm.util.readAll(temp)
            else
                json = python:yaml2json(file)
                zpm.util.writeAll(temp, json)
            end
        else
            json = zpm.util.readAll(file)
        end
        json = zpm.json.decode(json)
    end    
    return json
end

function zpm.ser.prettify(file, python)

    if not python then
        python = zpm.loader.python
    end

    return python:prettifyJSON(file)
end

function zpm.ser.isYAML(file)
    
    return file:endswith(".yml") or file:endswith(".yaml")
end

function zpm.ser.isJSON(file)
    
    return file:endswith(".json")
end