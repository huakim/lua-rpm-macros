local lua_sub={}

function lua_sub.parse(arg, opt)
 if not luarocks_subpackages_locked
 then
  local parser = require('luadist_parser')
  parser['_LUA_DIST_'] = true
  local flags = ''
  if arg == nil
  then
   arg = {}
  end
  if opt == nil
  then
   opt = {}
  end
  if opt.f
  then
   flags = 'f'
  end
  luarocks_subpackages_locked = true
  local tmpfile=os.tmpname()
  local specfile=rpm.expand('%_specfile')
 
  local random_f = string.format('%09x', math.floor(math.random()*(2^6^2)))
  local files_section = '-f '..random_f..'_files.list'
 
  rpm.define('lua_files '..files_section)
  rpm.define('lua_scriplets -f '..random_f..'_scriplets.list')
 
  local file2=rpm.open(specfile, 'r')
  local lua_version = rpm.expand('%lua_version')
  local lua_version_nodots = rpm.expand('%lua_version_nodots')
  rpm.define('lua_version %%{lua_version}')
  rpm.define('lua_version_nodots %%{lua_version_nodots}')
  local file=rpm.open(tmpfile, 'w')
  file:write(rpm.expand(file2:read()))
  file:close()
  file2:close()
 
  rpm.execute(
   rpm.expand('%__python3'),
   rpm.expand('%__lua_subpackages_helper'),
   'tmp',tmpfile,
   'specfile',tmpfile,
   'random',random_f,
   'sourcedir',rpm.expand('%_sourcedir'),
   'version', rpm.expand('%luarocks_pkg_version'),
   'luajit_version',rpm.expand('%luajit_lua_version_compat'),
   'lua_version',lua_version,
   'lua_versions',rpm.expand('%lua_versions'),
   'name',rpm.expand('%name'),
   'summary',rpm.expand('%summary'),
   'package',rpm.expand('%luarocks_pkg_name'),
   'flags',flags
  )
 
  file=rpm.open(tmpfile, 'r')
  print(file:read())
  file:close()
 
  if not rpm.isdefined('luarocks_pkg_build')
  then
   rpm.define("luarocks_pkg_build() %{luarocks_build_luaver %1}")
  end
 
  if not rpm.isdefined('luarocks_pkg_install')
  then
   rpm.define("luarocks_pkg_install() %{luarocks_install_luaver %1}")
  end
 
  local build = [[
 
 for i in %{lua_versions}
 do
   %luarocks_pkg_build ${i}
 done
 
 ]];
 
  local install = [[
 
 for i in %{lua_versions}
 do
   %luarocks_pkg_install ${i}
 done
 
 ]];
 
  local name = rpm.expand('%{name}')
  if name:sub(1, 4) == 'lua-' then name = name:sub(5); end
 
  lua_name='%{lua_flavor}-'..name
  files_section = ' -n '..lua_name
 
  if opt.f
  then
   files_section = files_section..' -f %{lua_flavor}_files.list'
   local genlist = [[
 for i in %{lua_versions}
 do
   %{_luarocks_genlist $i "lua${i//./}_files.list"}
 done
 ]]
   rpm.define('lua_generate_file_list %{_require_luadist}%{expand:'..genlist..'}')
  end
 
  rpm.define('luarocks_subpackages_build %{_require_luadist}%{expand:'..build..'}')
  rpm.define('luarocks_subpackages_install %{_require_luadist}%{expand:'..install..'}')
  rpm.define('lua_version '..lua_version)
  rpm.define('lua_version_nodots '..lua_version_nodots)
  rpm.define('lua_files '..files_section)
  rpm.define('lua_scriplets -n '..lua_name)
 
 end
end

return lua_sub
