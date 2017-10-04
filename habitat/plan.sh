pkg_name=chef-dk
pkg_origin=chef
pkg_maintainer="The Chef Maintainers <humans@chef.io>"
pkg_description="The Chef Client"
pkg_version=$(cat ../VERSION)
pkg_source=nosuchfile.tar.gz
pkg_filename=${pkg_dirname}.tar.gz
pkg_license=('Apache-2.0')
pkg_bin_dirs=(bin)
pkg_build_deps=(core/make core/gcc core/coreutils core/git)
# NOTE: core/openssl is set here to the exact version that
# core/ruby/2.4.2/20170914220737 was built with. In the future ruby should be
# automatically built when openssl is updated and we can change our dep back to
# just `core/openssl`
pkg_deps=(core/glibc core/busybox-static core/ruby core/libxml2 core/libxslt core/libiconv core/xz core/zlib core/bundler core/openssl/1.0.2j/20170513215106 core/cacerts core/libffi)
pkg_svc_user=root

do_download() {
  build_line "Fake download! Creating archive of latest repository commit."
  # source is in this repo, so we're going to create an archive from the
  # appropriate path within the repo and place the generated tarball in the
  # location expected by do_unpack
  cd $PLAN_CONTEXT/../
  git archive --prefix=${pkg_name}-${pkg_version}/ --output=$HAB_CACHE_SRC_PATH/${pkg_filename} HEAD
}

do_verify() {
  build_line "Skipping checksum verification on the archive we just created."
  return 0
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
  export CPPFLAGS="${CPPFLAGS} ${CFLAGS}"

  local _bundler_dir=$(pkg_path_for bundler)
  local _libxml2_dir=$(pkg_path_for libxml2)
  local _libxslt_dir=$(pkg_path_for libxslt)
  local _zlib_dir=$(pkg_path_for zlib)

  export GEM_HOME=${pkg_prefix}
  export GEM_PATH=${_bundler_dir}:${GEM_HOME}

  export NOKOGIRI_CONFIG="--use-system-libraries --with-zlib-dir=${_zlib_dir} --with-xslt-dir=${_libxslt_dir} --with-xml2-include=${_libxml2_dir}/include/libxml2 --with-xml2-lib=${_libxml2_dir}/lib"
  bundle config --local build.nokogiri '${NOKOGIRI_CONFIG}'

  bundle config --local silence_root_warning 1

  bundle install --without dep_selector --no-deployment --jobs 2 --retry 5 --path $pkg_prefix

  bundle exec 'rake install:local'
}

do_install() {

  mkdir -p $pkg_prefix/bin

  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/bin chef-dk
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/bin chef
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/bin ohai
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/bin foodcritic
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/bin test-kitchen
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/bin berkshelf
  bundle exec appbundler $HAB_CACHE_SRC_PATH/$pkg_dirname $pkg_prefix/bin inspec

  if [[ `readlink /usr/bin/env` = "$(pkg_path_for coreutils)/bin/env" ]]; then
    build_line "Removing the symlink we created for '/usr/bin/env'"
    rm /usr/bin/env
  fi

  wrap_ruby_bin "$pkg_prefix/bin/chef"
  wrap_ruby_bin "$pkg_prefix/bin/chef-client"
  wrap_ruby_bin "$pkg_prefix/bin/chef-apply"
  wrap_ruby_bin "$pkg_prefix/bin/chef-shell"
  wrap_ruby_bin "$pkg_prefix/bin/chef-solo"
  wrap_ruby_bin "$pkg_prefix/bin/ohai"
  wrap_ruby_bin "$pkg_prefix/bin/knife"
  wrap_ruby_bin "$pkg_prefix/bin/kitchen"
  wrap_ruby_bin "$pkg_prefix/bin/berks"
  wrap_ruby_bin "$pkg_prefix/bin/foodcritic"
  wrap_ruby_bin "$pkg_prefix/bin/inspec"
}

# Stubs
do_strip() {
  return 0
}

# Copied from https://github.com/habitat-sh/core-plans/blob/f84832de42b300a64f1b38c54d659c4f6d303c95/bundler/plan.sh#L32
wrap_ruby_bin() {
  local bin="$1"
  build_line "Adding wrapper $bin to ${bin}.real"
  mv -v "$bin" "${bin}.real"
  cat <<EOF > "$bin"
#!$(pkg_path_for busybox-static)/bin/sh
set -e
if test -n "$DEBUG"; then set -x; fi
export GEM_HOME="$pkg_prefix/ruby/2.4.0/"
export GEM_PATH="$(hab pkg path core/ruby)/lib/ruby/gems/2.4.0:$(hab pkg path core/bundler):$pkg_prefix/ruby/2.4.0/:$GEM_HOME"
export SSL_CERT_FILE=$(hab pkg path core/cacerts)/ssl/cert.pem 
export APPBUNDLER_ALLOW_RVM=true
unset RUBYOPT GEMRC
exec $(pkg_path_for ruby)/bin/ruby ${bin}.real \$@
EOF
  chmod -v 755 "$bin"
}
