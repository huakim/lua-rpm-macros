Name: lua-rpm-macros
Version: 1.1.9
Release: 0
Summary: Luarocks generator macros
License: GPLv3
Source0: %{name}-%{version}.tar.xz
BuildArch: noarch

Requires: luarocks-subpackages-macros
Requires: lua-macros
Requires: luarocks-macros
Requires: luajit-macros

%package -n luajit-macros
Summary: %{summary}

%package -n luarocks-macros
Summary: %{summary}

%if 0%{?suse_version}
Requires: lua-rpm-macros
%else
Requires: lua-macros

%package -n lua-macros
Summary: %{summary}

%description -n lua-macros
%{summary}.

%files -n lua-macros
%{_rpmmacrodir}/macros.lua-suse
%endif

%description
%{summary}.

%description -n luarocks-macros
%{summary}.

%description -n luajit-macros
%{summary}.

%prep
%autosetup -p1 -n %{name}-%{version}

%install

macrodir=%{_rpmmacrodir}
luadir=%{_rpmluadir}
configdir=%{_rpmconfigdir}
destdir=%{buildroot}
source $(pwd)/install.sh


%files -n luarocks-macros
%{_rpmmacrodir}/macros.luarocks
%{_rpmluadir}/luadist_parser.lua

%files -n luajit-macros
%{_rpmmacrodir}/macros.luajit

%if 0%{?suse_version}
%files

%package -n luarocks-subpackages-macros
Summary: %{summary}
Requires: python3-specfile
Requires: luarocks-macros
Requires: luajit-macros

%description -n luarocks-subpackages-macros
%{summary}.

%files -n luarocks-subpackages-macros
%{_rpmmacrodir}/macros.luarocks_subpackages
%{_rpmconfigdir}/lua_subpackages_helper.py
%{_rpmluadir}/luarocks_subpackages.lua
%else
%exclude %{_rpmmacrodir}/macros.lua-suse
%exclude %{_rpmmacrodir}/macros.luarocks_subpackages
%exclude %{_rpmconfigdir}/lua_subpackages_helper.py
%exclude %{_rpmluadir}/luarocks_subpackages.lua
%endif



