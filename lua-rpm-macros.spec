Name: lua-rpm-macros
Version: 1.0.2
Release: 0
Summary: Luarocks generator macros
License: GPLv3
Source0: %{name}.tar
BuildArch: noarch
Requires: luarocks-subpackages-macros
Requires: luarocks-macros
Requires: lua-macros

%package -n luarocks-macros
Requires: lua-macros
Summary: %{summary}

%package -n luarocks-subpackages-macros
Summary: %{summary}
Requires: python3-specfile
Requires: luarocks-macros

%description
%{summary}.

%description -n luarocks-subpackages-macros
%{summary}.

%description -n luarocks-macros
%{summary}.

%prep
%autosetup -p1 -n %{name}

%install

macrodir=%{_rpmmacrodir}
luadir=%{_rpmluadir}
configdir=%{_rpmconfigdir}
destdir=%{buildroot}
. install.sh

%files

%files -n luarocks-macros
%{_rpmmacrodir}/macros.luarocks
%{_rpmluadir}/luadist_parser.lua

%files -n luarocks-subpackages-macros
%{_rpmmacrodir}/macros.luarocks_subpackages
%{_rpmconfigdir}/lua_subpackages_helper.py
%{_rpmluadir}/luarocks_subpackages.lua

