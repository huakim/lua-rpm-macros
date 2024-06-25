#!/usr/bin/python3
from sys import argv
import itertools
import specfile as SpecFileParser
arg_dict = {'tmp', 'specfile', 'lua_versions', 'flags', 'lua_version', 'random', 'package', 'name', 'version', 'summary'}

glob_temp = globals()

for i in range(1, len(argv), 2):
    key = argv[i]
    value = argv[i+1]
    if key in arg_dict:
        glob_temp[key] = value

def scriplet(prefix, postfix):
    name = prefix + postfix
    return (name, f'{name} -f {random}_scriplets.list')

files_section = f'files -f {random}_files.list'
scriplet_sections = [ scriplet(*i) for i in itertools.product(
        ('pre', 'post'),
        ('', 'trans', 'un')
    )]

lua_versions = lua_versions.split()

expand_files = 'f' in flags

multi_sections = { i: SpecFileParser.Specfile(
    specfile, macros=[ ( 'lua_version', i ), ('luarocks_subpackages', '#'), ('lua_files', '-f lua_subpackages.list') ]
    ) for i in lua_versions }

spec = multi_sections[lua_version]
sections = spec.parsed_sections

tag_dict = {}
tag_names = {"Requires",
    "BuildRequires",
    "Provides",
    "Recommends",
    "Suggests",
    "Conflicts",
    "Obsoletes",
    "Supplements",
    "Enhances",
    "Requires(pre)",
    "Requires(preun)",
    "Requires(post)",
    "Requires(postun)",
    "Requires(pretrans)",
    "Requires(posttrans)"}

#spectags={
#'summary': 'Sum',
#'version': '0',
#'name': ''
#}

#for i in spec.tags(spec.parsed_sections.get('package')).content.data:
#    i_name = i.name
#    i_value = i.value
#    if i_name in spectags:
#        spectags[i_name.lower()] = i_value

#globals().update(spectags)

description = '\n'.join(sections.get('description').data)
if not description.strip():
    description = summary + '.'

def section_list(sections, data):
    return '\n'.join(sections.get(data).data)

pkg_name = name

if name[:4] == 'lua-':
    name = name[4:]

fileout = open(tmp, 'w')

def print(a):
    fileout.write(a)
    fileout.write('\n')

for i in lua_versions:
    prefix = 'lua' + i.replace('.','')
    iname = f'{prefix}-{name}'
    print(f'%package -n {iname}')
    print(f'Summary: {summary}')

    spec_i = multi_sections[i]
    sections_i = spec_i.parsed_sections

    for itag in spec_i.tags(sections_i.get('package')).content.data:
        i_name = itag.name
        i_value = itag.value
        if i_name in tag_names:
            print(f'{i_name}: {i_value}')

    if i == lua_version:
        print(f'Provides: {pkg_name} = {version}')
        print(f'Provides: luadist({package}) = {version}')
    print(f'Requires: Lua(API) = {i}')
    print(f'%description -n {iname}')

    print(description)

    if i != lua_version:
        for scrname, scriplet in scriplet_sections:
            if scriplet in sections_i:
                print (f'%{scrname} -n {iname}')
                print(section_list(sections_i, scriplet))

        if files_section in sections_i:
            if expand_files:
                print(f'%files -n {iname} -f {prefix}_files.list')
            else:
                print(f'%files -n {iname}')
            print(section_list(sections_i, files_section))



fileout.close()
