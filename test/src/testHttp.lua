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

function Test:testHttp()

    local loader = Loader:new()
    u.assertNotNil(loader.http)
end

function Test:testHttp_get()    
  
    local loader = Loader:new()
    u.assertStrContains(loader.http:get("http://example.com/"), "This domain is established to be used for illustrative examples in documents.")
end

function Test:testHttp_getHeaders()    
    
    local loader = Loader:new()
    u.assertStrContains(loader.http:get("http://scooterlabs.com/echo", {testHeader="FOOOO"}), "[testHeader] => FOOOO")
end

function Test:testHttp_getHeaders2()    
    
    local loader = Loader:new()
    local result = loader.http:get("http://scooterlabs.com/echo", {testHeader="FOOOO", foo="bar"})
    u.assertStrContains(result, "[testHeader] => FOOOO")
    u.assertStrContains(result, "[foo] => bar")
end

function Test:testHttp_download()    
    
    local loader = Loader:new()
    loader.http:download("http://scooterlabs.com/echo", "test.txt", {testHeader="FOOOO", foo="bar"})
    local str = zpm.util.readAll("test.txt")
    u.assertStrContains(str, "[testHeader] => FOOOO")
    u.assertStrContains(str, "[foo] => bar")
    os.remove("test.txt")
end

function Test:testHttp_download2()    
    
    local loader = Loader:new()
    loader.http:download("http://example.com/", "test.txt")
    local str = zpm.util.readAll("test.txt")
    u.assertStrContains(str, "This domain is established to be used for illustrative examples in documents.")
    os.remove("test.txt")
end

function Test:testHttp_downloadFromZipTo()    
    
    local loader = Loader:new()
    local downloaded = loader.http:downloadFromZipTo("https://github.com/premake/premake-core/releases/download/v5.0.0.alpha4/premake-5.0.0.alpha4-windows.zip", "./")
    
    u.assertEquals(#downloaded,1)
    u.assertStrContains(downloaded[1],".zip")
    u.assertTrue(os.isfile(downloaded[1]))
    u.assertTrue(os.isfile("./premake5.exe"))
    
    os.remove(downloaded[1])
    os.remove("./premake5.exe")
end

function Test:testHttp_downloadFromTarGzTo()   
 
    if not os.is("windows") then
        local loader = Loader:new()
        local downloaded = loader.http:downloadFromTarGzTo("https://github.com/premake/premake-core/releases/download/v5.0.0.alpha4/premake-5.0.0.alpha4-linux.tar.gz", "./")
    
        u.assertEquals(#downloaded,1)
        u.assertStrContains(downloaded[1],".tar.gz")
        u.assertTrue(os.isfile(downloaded[1]))
        u.assertTrue(os.isfile("./premake5"))
    
        os.remove(downloaded[1])
        os.remove("./premake5")
    end
end

function Test:testHttp_downloadFromZip()    
    
    local loader = Loader:new()
    local downloaded = loader.http:downloadFromZipTo("https://github.com/premake/premake-core/releases/download/v5.0.0.alpha4/premake-5.0.0.alpha4-windows.zip")
    
    u.assertEquals(#downloaded,1)
    u.assertStrContains(downloaded[1],".zip")
    u.assertTrue(os.isfile(downloaded[1]))    
    u.assertTrue(downloaded[1]:contains(loader.temp))    
    os.remove(downloaded[1])
end

function Test:testHttp_downloadFromTarGz()   
 
    if not os.is("windows") then
        local loader = Loader:new()
        local downloaded = loader.http:downloadFromTarGzTo("https://github.com/premake/premake-core/releases/download/v5.0.0.alpha4/premake-5.0.0.alpha4-linux.tar.gz")
    
        u.assertEquals(#downloaded,1)
        u.assertStrContains(downloaded[1],".tar.gz")
        u.assertTrue(os.isfile(downloaded[1]))    
        u.assertTrue(downloaded[1]:contains(loader.temp))  
        os.remove(downloaded[1])
    end
end

function Test:testHttp_downloadFromArchive()    
    
    local loader = Loader:new()
    local downloaded = loader.http:downloadFromArchive("https://github.com/premake/premake-core/releases/download/v5.0.0.alpha4/premake-5.0.0.alpha4-windows.zip")
    
    u.assertEquals(#downloaded,1)
    u.assertStrContains(downloaded[1],".zip")
    u.assertTrue(os.isfile(downloaded[1]))    
    u.assertTrue(downloaded[1]:contains(loader.temp))    
    os.remove(downloaded[1])
end

function Test:testHttp_downloadFromArchive2()   
 
    if not os.is("windows") then
        local loader = Loader:new()
        local downloaded = loader.http:downloadFromArchive("https://github.com/premake/premake-core/releases/download/v5.0.0.alpha4/premake-5.0.0.alpha4-linux.tar.gz")
    
        u.assertEquals(#downloaded,1)
        u.assertStrContains(downloaded[1],".tar.gz")
        u.assertTrue(os.isfile(downloaded[1]))    
        u.assertTrue(downloaded[1]:contains(loader.temp))  
        os.remove(downloaded[1])
    end
end