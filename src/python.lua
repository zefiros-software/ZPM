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

Python = newclass "Python"

function Python:init(loader)

    self.loader = loader
end

function Python:yaml2json(yaml)

    return self(("%s %s"):format(path.join(zpm.env.getScriptPath(), "../py/yaml2json.py"), yaml))
end

function Python:prettifyJSON(json)

    return self(("%s %s"):format(path.join(zpm.env.getScriptPath(), "../py/prettifyjson.py"), json))
end

function Python:update()

    self:conda("config --set always_yes yes --set changeps1 no")
    self:conda("update --all --yes")
end

function Python:__call(command)

    return os.outputoff("%s %s", self:_getPythonExe(), command)
end

function Python:conda(command)

    self:_executef("%s %s", zpm.util.getExecutable("conda"), command)
end

function Python:pip(command)

    self:_executef("%s %s", zpm.util.getExecutable("pip"), command)
end

function Python:_getBinDirectory()
    
    return path.join(self:_getDirectory(), iif(os.is("windows"), "Scripts", "bin"))
end

function Python:_getDirectory()
    
    return path.join(zpm.env.getDataDirectory(), "conda")
end

function Python:_execute(...)
    
    os.executef("%s/%s", self:_getBinDirectory(), string.format(...))
end

function Python:_getPythonExe()
    
    return path.join(self:_getDirectory(), zpm.util.getExecutable(iif(os.is("windows"), "python", "bin/python")))
end