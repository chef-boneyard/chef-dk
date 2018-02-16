pkg_name=chef-dk
pkg_origin=chef
pkg_maintainer="The Chef Maintainers <humans@chef.io>"
pkg_description="The Chef Developer Kit"
pkg_license=('Apache-2.0')
pkg_bin_dirs=(bin)
pkg_build_deps=(
  core/make
  core/gcc
  core/coreutils
  core/git
)

pkg_deps=(
  core/glibc
  core/busybox-static
  core/ruby
  core/libxml2
  core/libxslt
  core/libiconv
  core/xz
  core/zlib
  core/bundler
  core/openssl
  core/cacerts
  core/libffi
)

pkg_svc_user=root

pkg_version() {
  cat ../VERSION
}

do_before() {
  do_default_before
  update_pkg_version
}

do_download() {
  # Instead of downloading, build a gem based on the source in src/
  cd $PLAN_CONTEXT/..
  gem build $pkg_name.gemspec
}

do_verify() {
  return 0
}

do_unpack() {
  # Unpack the gem we built to the source cache path. Building then unpacking
  # the gem reuses the file inclusion/exclusion rules defined in the gemspec.
  gem unpack $PLAN_CONTEXT/../$pkg_name-$pkg_version.gem --target=$HAB_CACHE_SRC_PATH
}

do_prepare() {
  export OPENSSL_LIB_DIR=$(pkg_path_for openssl)/lib
  export OPENSSL_INCLUDE_DIR=$(pkg_path_for openssl)/include
  export SSL_CERT_FILE=$(pkg_path_for cacerts)/ssl/cert.pem

  build_line "Setting link for /usr/bin/env to 'coreutils'"
  [[ ! -f /usr/bin/env ]] && ln -s $(pkg_path_for coreutils)/bin/env /usr/bin/env

  return 0
}

do_build() {
  cd $CACHE_PATH
  export CPPFLAGS="${CPPFLAGS} ${CFLAGS}"

  local _bundler_dir=$(pkg_path_for bundler)
  local _libxml2_dir=$(pkg_path_for libxml2)
  local _libxslt_dir=$(pkg_path_for libxslt)
  local _zlib_dir=$(pkg_path_for zlib)

  export GEM_HOME=${pkg_prefix}
  export GEM_PATH=${_bundler_dir}:${GEM_HOME}

  export NOKOGIRI_CONFIG="--use-system-libraries --with-zlib-dir=${_zlib_dir} --with-xslt-dir=${_libxslt_dir} --with-xml2-include=${_libxml2_dir}/include/libxml2 --with-xml2-lib=${_libxml2_dir}/lib"
  bundle config --local build.nokogiri "${NOKOGIRI_CONFIG}"

  bundle config --local silence_root_warning 1

  bundle install --without dep_selector --no-deployment --jobs 2 --retry 5 --path $pkg_prefix

  bundle exec 'rake install:local'
}

do_install() {
  cd $CACHE_PATH
  mkdir -p $pkg_prefix/ruby-bin

  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/ruby-bin chef-dk
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/ruby-bin chef
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/ruby-bin ohai
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/ruby-bin foodcritic
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/ruby-bin test-kitchen
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/ruby-bin berkshelf
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/ruby-bin inspec

  if [[ `readlink /usr/bin/env` = "$(pkg_path_for coreutils)/bin/env" ]]; then
    build_line "Removing the symlink we created for '/usr/bin/env'"
    rm /usr/bin/env
  fi

  mkdir -p $pkg_prefix/bin

  wrap_ruby_bin "chef"
  wrap_ruby_bin "chef-client"
  wrap_ruby_bin "chef-apply"
  wrap_ruby_bin "chef-shell"
  wrap_ruby_bin "chef-solo"
  wrap_ruby_bin "ohai"
  wrap_ruby_bin "knife"
  wrap_ruby_bin "kitchen"
  wrap_ruby_bin "berks"
  wrap_ruby_bin "foodcritic"
  wrap_ruby_bin "inspec"
}

# Stubs
do_strip() {
  return 0
}

# Copied from https://github.com/habitat-sh/core-plans/blob/f84832de42b300a64f1b38c54d659c4f6d303c95/bundler/plan.sh#L32
wrap_ruby_bin() {
  local bin_basename="$1"
  local real_cmd="$pkg_prefix/ruby-bin/$bin_basename"
  local wrapper="$pkg_prefix/bin/$bin_basename"

  build_line "Adding wrapper $wrapper to $real_cmd"
  cat <<EOF > "$wrapper"
#!$(pkg_path_for busybox-static)/bin/sh
set -e
if test -n "$DEBUG"; then set -x; fi
export GEM_HOME="$pkg_prefix/ruby/2.4.0/"
export GEM_PATH="$(hab pkg path core/ruby)/lib/ruby/gems/2.4.0:$(hab pkg path core/bundler):$pkg_prefix/ruby/2.4.0/:$GEM_HOME"
export SSL_CERT_FILE=$(hab pkg path core/cacerts)/ssl/cert.pem 
export APPBUNDLER_ALLOW_RVM=true
unset RUBYOPT GEMRC
exec $(pkg_path_for ruby)/bin/ruby ${real_cmd} \$@
EOF
  chmod -v 755 "$wrapper"
}
