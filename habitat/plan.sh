pkg_name=chef-dk
pkg_origin=chef
pkg_maintainer="The Chef Maintainers <humans@chef.io>"
pkg_description="The Chef Developer Kit"
pkg_license=('Apache-2.0')
pkg_bin_dirs=(bin)
pkg_svc_user=root
pkg_build_deps=(
  core/make
  core/gcc
  core/git
)

# declaring it once here avoids needing to replace it
# in multple spots in the plan when it changes
ruby_pkg=core/ruby25

pkg_deps=(
  core/glibc
  core/busybox-static
  # yes, this is weird
  ${ruby_pkg}
  core/libxml2
  core/libxslt
  core/pkg-config
  core/xz
  core/zlib
  core/bundler
  core/openssl
  core/cacerts
  core/libffi
  core/libarchive
)

pkg_version() {
  cat "$SRC_PATH/VERSION"
}

do_before() {
  do_default_before
  update_pkg_version
}

do_download() {
  build_line "Building gem from source. (${SRC_PATH}/${pkg_name}.gemspec)"
  ( cd "${SRC_PATH}" || exit_with "unable to enter hab-src directory" 1
    gem build "${pkg_name}.gemspec"
  )
}

do_verify() {
  return 0
}

do_unpack() {
  # Unpack the gem we built to the source cache path. Building then unpacking
  # the gem reuses the file inclusion/exclusion rules defined in the gemspec.
  build_line "Unpacking gem into hab-cache directory. ($HAB_CACHE_SRC_PATH)"
  gem unpack "${SRC_PATH}/${pkg_name}-${pkg_version}.gem" --target="$HAB_CACHE_SRC_PATH"
}

do_prepare() {
  export OPENSSL_LIB_DIR=$(pkg_path_for openssl)/lib
  export OPENSSL_INCLUDE_DIR=$(pkg_path_for openssl)/include
  export SSL_CERT_FILE=$(pkg_path_for cacerts)/ssl/cert.pem
  export RUBY_ABI_VERSION=$(ls $(pkg_path_for ${ruby_pkg})/lib/ruby/gems)
  build_line "Ruby ABI version appears to be ${RUBY_ABI_VERSION}"

  build_line "Setting link for /usr/bin/env to 'busybox-static'"
  if [ ! -f /usr/bin/env ]; then
    ln -s "$(pkg_interpreter_for core/busybox-static bin/env)" /usr/bin/env
  fi
}

do_build() {
  local _bundler_dir
  local _libxml2_dir
  local _libxslt_dir
  local _zlib_dir
  export NOKOGIRI_CONFIG
  export GEM_HOME
  export GEM_PATH

  _bundler_dir=$(pkg_path_for bundler)
  _libxml2_dir=$(pkg_path_for libxml2)
  _libxslt_dir=$(pkg_path_for libxslt)
  _zlib_dir=$(pkg_path_for zlib)

  NOKOGIRI_CONFIG="--use-system-libraries \
    --with-zlib-dir=${_zlib_dir} \
    --with-xslt-dir=${_libxslt_dir} \
    --with-xml2-include=${_libxml2_dir}/include/libxml2 \
    --with-xml2-lib=${_libxml2_dir}/lib \
    --without-iconv"
  GEM_HOME="$pkg_prefix"
  GEM_PATH="${_bundler_dir}:${GEM_HOME}"

  ( cd "$CACHE_PATH" || exit_with "unable to enter hab-cache directory" 1
    bundle config --local build.nokogiri "$NOKOGIRI_CONFIG"
    bundle config --local silence_root_warning 1
    bundle install --without dep_selector --no-deployment --jobs 2 --retry 5 --path "$pkg_prefix"
    gem build ${pkg_name}.gemspec
  )
}

do_install() {
  export ruby_bin_dir
  ruby_bin_dir="$pkg_prefix/ruby-bin"

  build_line "Installing generated gem. (${CACHE_PATH}/${pkg_name}-${pkg_version}.gem)"
  gem install --no-doc "${CACHE_PATH}/${pkg_name}-${pkg_version}.gem"

  build_line "Creating bin directories"
  mkdir -p "$ruby_bin_dir"
  mkdir -p "$pkg_prefix/bin"

  # Appbundling gems speeds up runtime by creating binstubs for Ruby executables with
  # versions of dependencies already resolved
  pushd "$CACHE_PATH" || exit_with "unable to enter hab-cache directory" 1
    set -x
    bundle exec appbundler "$HAB_CACHE_SRC_PATH/$pkg_dirname" "$ruby_bin_dir" "chef" --without "docgen,chefstyle" >/dev/null
    bundle exec appbundler "$HAB_CACHE_SRC_PATH/$pkg_dirname" "$ruby_bin_dir" "dco" "foodcritic" --without "development" >/dev/null
    bundle exec appbundler "$HAB_CACHE_SRC_PATH/$pkg_dirname" "$ruby_bin_dir" "inspec" --without "deploy,tools,maintenance,integration,test" >/dev/null
    bundle exec appbundler "$HAB_CACHE_SRC_PATH/$pkg_dirname" "$ruby_bin_dir" "test-kitchen" --without "changelog,debug,docs" >/dev/null

    export gems_to_appbundle
    gems_to_appbundle=(
      berkshelf
      chef-apply
      chef-dk
      chef-vault
      cookstyle
      ohai
      opscode-pushy-client
    )
    bundle exec appbundler "$HAB_CACHE_SRC_PATH/$pkg_dirname" "$ruby_bin_dir" ${gems_to_appbundle[*]} --without "changelog" >/dev/null
    set +x
  popd

  build_line "Link the appbundled binstubs into the package's bin directory"
  for exe in "$ruby_bin_dir"/*; do
    wrap_ruby_bin "$(basename "${exe}")"
  done

  if [ "$(readlink /usr/bin/env)" = "$(pkg_interpreter_for core/busybox-static bin/env)" ]; then
    build_line "Removing the symlink created for '/usr/bin/env'"
    rm /usr/bin/env
  fi
}

# Stubs
do_strip() {
  return 0
}

# Copied from https://github.com/habitat-sh/core-plans/blob/f84832de42b300a64f1b38c54d659c4f6d303c95/bundler/plan.sh#L32
wrap_ruby_bin() {
  local bin_basename
  local real_cmd
  local wrapper
  bin_basename="$1"
  real_cmd="$ruby_bin_dir/$bin_basename"
  wrapper="$pkg_prefix/bin/$bin_basename"

  build_line "Adding wrapper for $bin_basename."
  build_line " - from: $wrapper"
  build_line " -   to: $real_cmd"
  cat <<EOF > "$wrapper"
#!$(pkg_path_for busybox-static)/bin/sh
set -e
if test -n "\$DEBUG"; then set -x; fi
export GEM_HOME="$pkg_prefix/ruby/${RUBY_ABI_VERSION}/"
export GEM_PATH="$(pkg_path_for ${ruby_pkg})/lib/ruby/gems/${RUBY_ABI_VERSION}:$(hab pkg path core/bundler):$pkg_prefix/ruby/${RUBY_ABI_VERSION}/:$GEM_HOME"
export SSL_CERT_FILE=$(pkg_path_for core/cacerts)/ssl/cert.pem
export APPBUNDLER_ALLOW_RVM=true
unset RUBYOPT GEMRC
exec $(pkg_path_for ${ruby_pkg})/bin/ruby ${real_cmd} "\$@"
EOF
  chmod -v 755 "$wrapper"
}
