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

function Test:testConfigExists()
    u.assertNotEquals(Config, nil)
    u.assertIsTable(Config)
end

function Test:testConfig_Call()
    local conf = Config:new(nil)

    conf.values = {foo = "Bar"}
    
    u.assertEquals(conf("foo"), "Bar")
    u.assertNotEquals(conf("foo"), "bar")
end

function Test:testConfig_Call2()
    local conf = Config:new(nil)

    conf.values = {foo = {bar = "foo"}}
    
    u.assertEquals(conf("foo.bar"), "foo")
    u.assertNotEquals(conf("foo.bar"), "Far")
end

function Test:testConfig_CallSet()
    local conf = Config:new(nil)

    conf.values = {foo = {bar = "foo"}}
    conf("foo", "foo")
    u.assertEquals(conf("foo"), "foo")
    u.assertNotEquals(conf("foo"), "bar")
end

function Test:testConfig_CallSet2()
    local conf = Config:new(nil)

    conf.values = {foo = {bar = "foo"}}
    conf("foo.bar", "bar")
    u.assertEquals(conf("foo.bar"), "bar")
    u.assertNotEquals(conf("foo.bar"), "foo")
end

function Test:testConfig_CallSet3()
    local conf = Config:new(nil)

    conf.values = {foo = {bar = "foo"}}
    conf("foo.bar", "bar")
    conf("foo.bar2", "bar2")
    u.assertEquals(conf("foo.bar"), "bar")
    u.assertEquals(conf("foo.bar2"), "bar2")
    u.assertNotEquals(conf("foo.bar"), "foo")
end

function Test:testConfig_SetNotExists()
    local conf = Config:new(nil)
    u.assertErrorMsgContains("Failed to find the complete key 'foo.bar'", conf.set, conf, "foo.bar", 2 )
end

function Test:testConfig_SetNotExistsParents()
    local conf = Config:new(nil)

    u.assertIsNil( _OPTIONS["parents"])
    _OPTIONS["parents"] = true

    conf:set( "foo.bar", 2)
    u.assertEquals( conf("foo.bar"), 2 )
    u.assertEquals( conf("foo"), {bar = 2} )

    _OPTIONS["parents"] = nil
    u.assertIsNil( _OPTIONS["parents"])
end

function Test:testConfig_SetNotExistsParents2()
    local conf = Config:new(nil)

    u.assertIsNil( _OPTIONS["parents"])
    _OPTIONS["parents"] = true

    conf:set( "foo.bar", { foo = 2})
    u.assertEquals( conf("foo.bar"), { foo = 2} )
    u.assertEquals( conf("foo"), {bar = { foo = 2}} )

    _OPTIONS["parents"] = nil
    u.assertIsNil( _OPTIONS["parents"])
end
