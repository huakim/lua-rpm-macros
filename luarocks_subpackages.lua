local lua_sub={}

function lua_sub.parse(arg, opt)


if not luarocks_subpackages_locked
then

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

local build = [[

for i in %{lua_versions}
do
  dir=".luarocks/lua${i}"
  mkdir -p "${dir}"
  %luarocks_build --lua-version "${i}" "%{luarocks_pkg_rockspec}"
  mv '%{luarocks_pkg_prefix}'.*.rock "${dir}"
done

]];

local install = [[

for i in %{lua_versions}
do
  %luarocks_install --lua-version "${i}" ".luarocks/lua${i}/"'%{luarocks_pkg_prefix}'.*.rock
  rm -Rf %{buildroot}%{_bindir}
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

echo_module(){
  if test "$2" == "module"
  then
    local path=${4#"%{buildroot}"}
    # Print the file path
    echo "$path"
    # Get the directory part of the path
    local dir=$(dirname "$path")
    # Print the directories as %dir statements
    while [ "%{_libdir}/lua/$1:%{_datadir}/lua/$1" =~ "$dir" ]; do
      echo "%%dir $dir"
      dir=$(dirname "$dir")
    done
  fi
}


for i in %{lua_versions}
do
flist="lua${i//./}_files.list"
%__luarocks_admin --lua-version ${i} --tree="%{buildroot}%{_prefix}" make_manifest

tree="$(%__luarocks config variables.ROCKS_TREE --lua-version ${i} --tree="%{buildroot}%{_prefix}")"

echo "${tree#"%{buildroot}"}" > "$flist"

while read -r line; do
  echo_module "${i}" ${line} >> "$flist"

done <<< "$(%__luarocks --lua-version ${i} show --porcelain --tree="%{buildroot}%{_prefix}" "%{luarocks_pkg_name}")"

rm -Rf "${tree}/"{manifest,index}* ||:

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
