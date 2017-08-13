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

zpm.api.common = {
    http = 
    {
        download = http.download,
        escapeUrlParam = http.escapeUrlParam,
        get = http.get,
        post = http.post,
        reportProgress = http.reportProgress
    },
    os =
    {
        is64bit = os.is64bit,
        matchfiles = os.matchfiles,
        matchdirs = os.matchdirs,
        isdir = os.isdir,
        isfile = os.isfile,
        is = os.is,
        host = os.host,
        ishost = os.ishost,
        target = os.target,
        istarget = os.istarget,
        getenv = os.getenv
    },
    path =
    {
        join = path.join,
        normalize = path.normalize
    },
    noticef = noticef,
    warningf = warningf,
    errorf = errorf,
    notice = notice,
    warning = warning,
    error = error,
    zpm = {},
    string = string,
    table = table,
    print = print,
    _TARGET_OS = _TARGET_OS,
    _ARGS = _ARGS,
    _ACTION = _ACTION,
    _OPTIONS = _OPTIONS,
    _PREMAKE_DIR = _PREMAKE_DIR,
    _MAIN_SCRIPT = _MAIN_SCRIPT,
    _PREMAKE_VERSION = _PREMAKE_VERSION,
    _PREMAKE_COMMAND = _PREMAKE_COMMAND,
    _MAIN_SCRIPT_DIR = _MAIN_SCRIPT_DIR
}

function zpm.api.load(type, cursor)

    local env = table.deepcopy(zpm.api.common)


    local tdefault = zpm.util.indexTable(zpm.api, {type, "default"})

    if tdefault then
        tdefault(env, cursor)
    end

    local export = zpm.util.indexTable(zpm.api, {type, "export"})
    if export then
        for name, func in pairs(export) do
            env.zpm[name] = func(cursor)
        end
    end
    
    local global = zpm.util.indexTable(zpm.api, {type, "global"})
    if global then
        for name, func in pairs(global) do
            env[name] = func(cursor)
        end
    end
    return env
end