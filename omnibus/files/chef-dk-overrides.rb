# Lower level library pins
override :libedit,             version: "20130712-3.1"
## according to comment in omnibus-sw, latest versions don't work on solaris
# https://github.com/chef/omnibus-software/blob/aefb7e79d29ca746c3f843673ef5e317fa3cba54/config/software/libtool.rb#L23
override :libtool,             version: "2.4.2"
override :libxslt,             version: "1.1.28"
override :makedepend,          version: "1.0.5"
override :ruby,                version: "2.1.8"
override :rubygems,            version: "2.5.2"
override :bundler,             version: "1.11.2"
override :"util-macros",       version: "1.19.0"
override :xproto,              version: "7.0.28"
override :zlib,                version: "1.2.8"
# override :"libffi",          version: "3.2.1"
# override :"libiconv",        version: "1.14"
# override :"liblzma",         version: "5.2.2"
# override :libxml2,           version: "2.9.3"
# override :"ncurses",         version: "5.9"
# override :"pkg-config-lite", version: "0.28-1"
# override :"libyaml",         version: "0.1.6"

## These can float as they are frequently updated in a way that works for us
#override :"cacerts",                             # probably best to float?
#override :"openssl"                              # leave this?
