macrodir="${macrodir:-$(rpm --eval '%{_rpmmacrodir}')}"
luadir="${luadir:-$(rpm --eval '%{_rpmluadir}')}"
configdir="${configdir:-$(rpm --eval '%{_rpmconfigdir}')}"
destdir="${destdir:-/}"
install -Dm644 {,"${destdir}${macrodir}/"}macros.luarocks
install -Dm644 {,"${destdir}${macrodir}/"}macros.lua-suse
install -Dm644 {,"${destdir}${macrodir}/"}macros.luarocks_subpackages
install -Dm644 {,"${destdir}${luadir}/"}luarocks_subpackages.lua
install -Dm644 {,"${destdir}${luadir}/"}luadist_parser.lua
install -Dm755 {,"${destdir}${configdir}/"}lua_subpackages_helper.py
install -Dm644 {,"${destdir}${macrodir}/"}macros.luajit
