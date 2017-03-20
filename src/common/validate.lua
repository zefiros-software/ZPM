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

zpm.validate = {}

function zpm.validate.manifest(entry, name, vendor)

    zpm.sassert(entry ~= nil, "Manifest entry is empty!")

    zpm.sassert(name ~= nil, "No 'name' supplied in manifest definition!")
    zpm.sassert(vendor ~= nil, "No 'vendor' supplied in manifest definition!")
    zpm.sassert(entry.repository ~= nil, "No 'repository' supplied in manifest definition!")

    zpm.sassert(zpm.util.isAlphaNumeric(name), "'name' supplied in manifest definition must be alpha numeric!")
    zpm.sassert(name:len() <= 50, "'name' supplied in manifest definition exceeds maximum size of 50 characters!")
    zpm.sassert(name:len() >= 2, "'name' supplied in manifest definition must at least be 2 characters!")

    zpm.sassert(zpm.util.isAlphaNumeric(vendor), "'vendor' supplied in manifest definition must be alpha numeric!")
    zpm.sassert(vendor:len() <= 50, "'vendor' supplied in manifest definition exceeds maximum size of 50 characters!")
    zpm.sassert(vendor:len() >= 2, "'vendor' supplied in manifest definition must at least be 2 characters!")

    zpm.sassert(zpm.util.isGitUrl(entry.repository), "'repository' supplied in manifest definition is not a valid https git url!")

    zpm.sassert(not entry.definition or zpm.util.isGitUrl(entry.definition), "'definition' supplied in manifest definition is not a valid https git url!")

    return true
end

function zpm.validate.manifests(entry)

    zpm.sassert(entry.manifest ~= nil, "No 'manifest' file supplied in manifest definition!")

    return true
end