local luadist = {}

function luadist:rockspec_var(placeholder)
    local luarocks_rockspec = self.luarocks_rockspec
    if luarocks_rockspec == nil
    then
      local path = self:get_rockspec_file()
      if not pcall(function()
        local file = rpm.open(path, 'r')
        self.luarocks_rockspec = load(
[[
local _ENV = {}

]] .. file:read() .. [[

return _ENV
]])()
      end) then
        self.luarocks_rockspec = {}
      end
      luarocks_rockspec = self.luarocks_rockspec
    end
    return load('return function(lua) return lua.'..placeholder..' end')()(luarocks_rockspec)
end

function luadist:prepare_macros(name, template, template_type)
  if not rpm.isdefined(name)
  then
    if template_type == nil
    then
      template = template:gsub('(.?)%%{([^}]+)}', function(prefix, placeholder)
      if prefix == '%' then
        return '%{'..placeholder..'}'
      else
        if not prefix then
          prefix = ''
        end
        local retvar = self:rockspec_var(placeholder)
        if not retval then
          retval = '%{'..placeholder..'}'
        end
        return prefix .. retval
      end
    end):gsub('%%%%','%%')
    elseif template_type == 1
    then
      template = template()
    end
    rpm.define(name .. ' ' .. template)
    return template
  else
    return rpm.expand('%'..name)
  end
end

function luadist:essential_setup()
  self:get_rockspec()
  self:get_prefix()
  self:get_name()
  self:get_version()
  self:get_rockspec_file()
  return self
end

function luadist:get_rockspec()
  return self:prepare_macros('luarocks_pkg_rockspec', function () return self:get_prefix() .. '.rockspec' end, 1)
end

function luadist:get_prefix()
  return self:prepare_macros('luarocks_pkg_prefix', function () return self:get_name() .. '-' .. self:get_version() end , 1)
end

function luadist:get_name()
  return self:prepare_macros('luarocks_pkg_name', '%{package}')
end

function luadist:get_version()
  return self:prepare_macros('luarocks_pkg_version', '%{version}')
end

function luadist:get_rockspec_file()
  return self:prepare_macros('luarocks_rockspec_file', '%{SOURCE1}', 0)
end

function sh_str(value)
  return '"'..value:gsub("\\", "\\\\"):gsub('"','\\"'):gsub('`','\\`'):gsub('%$', '\\$')..'"'
end

function luadist:get_binary_source(binary)
  return rpm.expand('%{luarocks_treedir}/')..self:get_name()..'/'..self:get_version()..'/bin/'..binary
end

function luadist:print_lua_modules(str)
  local tab = self:rockspec_var(str)
  if tab then
    newline = string.char(10)
    for i, a in ipairs(tab) do
      self:parse_modreq({a}, {}, newline)
      print(newline)
    end
  end
end

function luadist:generate_buildrequires(arg, opt)
  if opt.b then
    self:print_lua_modules('build_dependencies')
  end
  if opt.c then
    self:print_lua_modules('test_dependencies')
  end
end

function luadist:get_lua_version()
  return rpm.expand('%{lua_version}')
end

function luadist:add_lua_binary(arg, opt)
  if #arg > 0 then
    local bindir = opt.b
    if not bindir then
      bindir = rpm.expand('%{_bindir}')
    end
    local binary = arg[1]
    prior = opt.p
    if not prior then
      prior = '25'
    end
    local lua_version = self:get_lua_version()
    local binary_ver = binary .. '-' .. lua_version
    local binary_dest = sh_str(bindir..'/'..binary)
    local binary_dest_ver = sh_str(bindir..'/'..binary_ver)
    local binary_src = sh_str(self:get_binary_source(binary))
    prior = sh_str(prior)
    binary = sh_str(binary)
    print('update-alternatives --install '..binary_dest..' '..binary..' '..binary_src..' '..prior..' ; update-alternatives --install '..binary_dest_ver..' '..binary_ver..' '..binary_src..' '..prior)
  end
end

function luadist:drop_lua_binary(arg, opt)
  if #arg > 0 then
    local binary = arg[1]
    print('update-alternatives --remove '..sh_str(binary)..' '..sh_str(self:get_binary_source(binary)))
  end
end

function luadist:parse_modreq(arg, opt, sep)
  if not sep then
    sep = ', '
  end
  if rpm.isdefined('lua_versions_nodots')
  then
    func = string.gmatch(rpm.expand('%lua_versions_nodots'), "[^%s]+")
    local flavor = func()
    goto named1
    ::named2::
    print(sep)
    ::named1::
    self:parse_req(arg, opt, 'lua'..flavor, true )
    flavor = func()
    if flavor
    then
      goto named2
    end
  else
    self:parse_req(arg, opt, nil, true )
  end
end

function luadist:parse_req(arg, opt, flavor, nodist)
  if #arg > 0
  then
    local name = arg[1]
    local flav = nil
    if flavor
    then
      flav = flavor
    elseif rpm.isdefined('lua_flavor')
    then
      flav = rpm.expand('%lua_flavor')
    end
    if (flav == nil)
    then
      if nodist
      then
        flav = 'lua'
      else
        flav = rpm.expand('lua%{lua_version}');
      end
    end
    if not (name == 'lua')
    then
      if nodist
      then
        name = flav .. '-' .. name
      else
        name = flav .. 'dist(' .. name .. ')'
      end
    else
      name = rpm.expand('%{?lua_api}%{?!lua_api:Lua(API)}')
    end
    if #arg > 2
    then
      local reg = "%.[^%.]*$"
      local grver
      local index
      local op = arg[2]
      local ver = arg[3]
      if op == '~='
      then
        grver = ver:sub(1,(ver:find(reg) or 0)-1)
        goto named1
      elseif opt == '~>'
      then
        grver = ver
        goto named1
      else
        name = name .. ' ' .. op .. ' ' .. ver
        goto named2
      end
    else
      goto named2
    end
    ::named1::
    index = grver:find(reg) or 0
    grver=grver:sub(1,index)..tostring(tonumber(grver:sub(index+1))+1)
    name='('..name..' >= '..ver..' and '..name..' < '..grver..')'

    ::named2::
    print(name)
  end
end

return luadist
