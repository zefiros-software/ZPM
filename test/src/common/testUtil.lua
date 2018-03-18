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

function Test:testUtil_ripairs()

    local i = {}
    local test = {1,2,3}
    for _, t in ripairs(test) do
        table.insert(i, t)
    end
    u.assertEquals(i, {3,2,1})
    u.assertNotEquals(i, test)
end

function Test:testUtil_traversePath()
    
    u.assertEquals(zpm.util.traversePath("/var/www"), {"/var/www", "/var"})
end

function Test:testUtil_isArray()
    
    u.assertTrue(zpm.util.isArray({"/var/www"}))
    u.assertTrue(zpm.util.isArray({"/var/www", "Var"}))
    u.assertTrue(zpm.util.isArray({}))
    u.assertFalse(zpm.util.isArray({var="foo"}))
end

function Test:testUtil_getGitUrl()
    
    u.assertEquals(zpm.util.getGitUrl("https://github.com/Zefiros-Software/ZPM.git"), "https://github.com/Zefiros-Software/ZPM.git")
    u.assertEquals(zpm.util.getGitUrl("git@github.com:Zefiros-Software/ZPM.git"), "git@github.com:Zefiros-Software/ZPM.git")
    u.assertEquals(zpm.util.getGitUrl("https://github.com/Zefiros-Software/ZPM.git?wefwef"), "https://github.com/Zefiros-Software/ZPM.git")
    u.assertEquals(zpm.util.getGitUrl("git@github.com:Zefiros-Software/ZPM.git?Wefwef"), "git@github.com:Zefiros-Software/ZPM.git")
    u.assertEquals(zpm.util.getGitUrl("http://github.com/Zefiros-Software/ZPM.git"), nil)
    u.assertEquals(zpm.util.getGitUrl("http://github.com/Zefiros-Software/ZPM.git?wefwef"), nil)
end

function Test:testUtil_isGitUrl()
    
    u.assertTrue(zpm.util.isGitUrl("https://github.com/Zefiros-Software/ZPM.git"))
    u.assertTrue(zpm.util.isGitUrl("git@github.com:Zefiros-Software/ZPM.git"))
    u.assertFalse(zpm.util.isGitUrl("https://github.com/Zefiros-Software/ZPM.git?wefwef"))
    u.assertFalse(zpm.util.isGitUrl("git@github.com:Zefiros-Software/ZPM.git?Wefwef"))
    u.assertFalse(zpm.util.isGitUrl("localhost"))
    u.assertFalse(zpm.util.isGitUrl("https://localhost"))
    u.assertFalse(zpm.util.isGitUrl("http://localhost"))
    u.assertFalse(zpm.util.isGitUrl("http://github.com/Zefiros-Software/ZPM.git"))
end

function Test:testUtil_hasGitUrl()
    
    u.assertTrue(zpm.util.hasGitUrl("https://github.com/Zefiros-Software/ZPM.git"))
    u.assertTrue(zpm.util.hasGitUrl("git@github.com:Zefiros-Software/ZPM.git"))
    u.assertTrue(zpm.util.hasGitUrl("https://github.com/Zefiros-Software/ZPM.git?wefwef"))
    u.assertTrue(zpm.util.hasGitUrl("git@github.com:Zefiros-Software/ZPM.git?Wefwef"))
    u.assertFalse(zpm.util.hasGitUrl("localhost"))
    u.assertFalse(zpm.util.hasGitUrl("https://localhost"))
    u.assertFalse(zpm.util.hasGitUrl("http://localhost"))
    u.assertFalse(zpm.util.hasGitUrl("http://github.com/Zefiros-Software/ZPM.git"))
    u.assertTrue(zpm.util.hasGitUrl("wefwef we we fgit@github.com:Zefiros-Software/ZPM.git"))
end

function Test:testUtil_hasUrl()
    
    u.assertTrue(zpm.util.hasUrl("https://github.com/Zefiros-Software/ZPM.git"))
    u.assertFalse(zpm.util.hasUrl("git@github.com:Zefiros-Software/ZPM.git"))
    u.assertTrue(zpm.util.hasUrl("https://github.com/Zefiros-Software/ZPM.git?wefwef"))
    u.assertFalse(zpm.util.hasUrl("git@github.com:Zefiros-Software/ZPM.git?Wefwef"))
    u.assertFalse(zpm.util.hasUrl("localhost"))
    u.assertTrue(zpm.util.hasUrl("https://localhost"))
    u.assertTrue(zpm.util.hasUrl("http://localhost"))
    u.assertTrue(zpm.util.hasUrl("http://github.com/Zefiros-Software/ZPM.git"))
    u.assertTrue(zpm.util.hasUrl(" wef wehttp://github.com/Zefiros-Software/ZPM.git"))
    u.assertFalse(zpm.util.hasUrl("wefwef we we fgit@github.com:Zefiros-Software/ZPM.git"))
end

function Test:testUtil_hideProtectedFile()
    
    zpm.loader = Loader()

    zpm.util.writeAll("test.txt", "HELLO")
    u.assertTrue(os.isfile("test.txt"))

    local to = zpm.util.hideProtectedFile("test.txt")

    u.assertFalse(os.isfile("test.txt"))
    u.assertTrue(os.isfile(to))

    os.remove(to)
    
    zpm.loader = nil
end