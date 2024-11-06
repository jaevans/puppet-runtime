component "yaml-cpp" do |pkg, settings, platform|
  pkg.url "https://github.com/jbeder/yaml-cpp.git"
  pkg.ref "refs/tags/yaml-cpp-0.6.2"

  # Build-time Configuration
  cmake_toolchain_file = ''
  make = 'make'
  mkdir = 'mkdir'
  cmake = if platform.name =~ /amazon-2-aarch64/
    '/usr/bin/cmake3'
  else
    'cmake'
  end

  if platform.is_cross_compiled_linux?
    # We're using the x86_64 version of cmake
    cmake = "/opt/pl-build-tools/bin/cmake"
    cmake_toolchain_file = "-DPL_TOOLS_ROOT=/opt/freeware -DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/#{settings[:platform_triple]}/pl-build-toolchain.cmake"
  elsif platform.is_solaris?
    if platform.os_version != '10'
      make = '/usr/bin/gmake'
    end

    if !platform.is_cross_compiled? && platform.architecture == 'sparc'
      pkg.environment "PATH", "$(PATH):/opt/pl-build-tools/bin"
    else
      # We always use the i386 build of cmake, even when cross-compiling on sparc
      cmake = "/opt/pl-build-tools/i386-pc-solaris2.#{platform.os_version}/bin/cmake"
      cmake_toolchain_file = "-DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/#{settings[:platform_triple]}/pl-build-toolchain.cmake"
      pkg.environment "PATH", "$(PATH):/opt/csw/bin"
    end
  elsif platform.is_macos?
    cmake_toolchain_file = ""
    cmake = "/usr/local/bin/cmake"
    if platform.is_cross_compiled?
      pkg.environment 'CXX', 'clang++ -target arm64-apple-macos11' if platform.name =~ /osx-11/
      pkg.environment 'CXX', 'clang++ -target arm64-apple-macos12' if platform.name =~ /osx-12/
    elsif platform.architecture == 'arm64' && platform.os_version.to_i >= 13
      pkg.environment 'CXX', 'clang++'
      cmake = "/opt/homebrew/bin/cmake"
    end

  elsif platform.is_windows?
    make = "#{settings[:gcc_bindir]}/mingw32-make"
    mkdir = '/usr/bin/mkdir'
    pkg.environment "PATH", "$(shell cygpath -u #{settings[:gcc_bindir]}):$(shell cygpath -u #{settings[:ruby_bindir]}):/cygdrive/c/Windows/system32:/cygdrive/c/Windows:/cygdrive/c/Windows/System32/WindowsPowerShell/v1.0"
    pkg.environment "CYGWIN", settings[:cygwin]
    cmake = "C:/ProgramData/chocolatey/bin/cmake.exe -G \"MinGW Makefiles\""
    cmake_toolchain_file = "-DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/pl-build-toolchain.cmake"
  elsif platform.name =~ /aix-7\.1-ppc|el-[56]|redhatfips-7|sles-(?:11)/
    cmake = "#{settings[:tools_root]}/bin/cmake"
    cmake_toolchain_file = "-DCMAKE_TOOLCHAIN_FILE=#{settings[:tools_root]}/pl-build-toolchain.cmake"
  else
    if platform.is_aix?
      pkg.environment "PATH", "$(PATH):/opt/freeware/bin"
      cmake = "/opt/freeware/bin/cmake"
    end
    pkg.environment 'CPPFLAGS', settings[:cppflags]
    pkg.environment 'CFLAGS', settings[:cflags]
    pkg.environment 'LDFLAGS', settings[:ldflags]
  end

  # Build Commands
  pkg.build do
    buildcmd = "#{cmake} \
      #{cmake_toolchain_file} \
      -DCMAKE_INSTALL_PREFIX=#{settings[:prefix]} \
      -DCMAKE_VERBOSE_MAKEFILE=ON \
      -DYAML_CPP_BUILD_TOOLS=0 \
      -DYAML_CPP_BUILD_TESTS=0 \
      -DBUILD_SHARED_LIBS=ON "
    buildcmd += "-DCMAKE_CXX_COMPILER='/opt/rh/devtoolset-7/root/usr/bin/g++'" if platform.name =~ /el-7/
    buildcmd += " .. "
      
    [ "#{mkdir} build",
      "cd build",
      buildcmd,
      "#{make} VERBOSE=1 -j$(shell expr $(shell #{platform[:num_cores]}) + 1)",
    ]
  end

  pkg.install do
    [ "cd build",
      "#{make} install",
    ]
  end
end
