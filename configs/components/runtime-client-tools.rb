# This component exists to link in the gcc and stdc++ runtime libraries.
component "runtime-client-tools" do |pkg, settings, platform|
  pkg.environment "PROJECT_SHORTNAME", "client-tools"

  if platform.is_windows?
    lib_type = platform.architecture == "x64" ? "seh" : "sjlj"
    ["libgcc_s_#{lib_type}-1.dll", 'libstdc++-6.dll', 'libwinpthread-1.dll'].each do |dll|
      pkg.install_file File.join(settings[:gcc_bindir], dll), File.join(settings[:bindir], dll)
    end

    # zlib is a runtime dependency of libcurl
    pkg.build_requires "pl-zlib-#{platform.architecture}"
    pkg.install_file "#{settings[:tools_root]}/bin/zlib1.dll", "#{settings[:bindir]}/zlib1.dll"
  elsif platform.name =~ /el-6|redhatfips-7/
    libbase = platform.architecture =~ /64/ ? 'lib64' : 'lib'
    libdir = "/opt/pl-build-tools/#{libbase}"
    pkg.add_source "file://resources/files/runtime/runtime.sh"
    pkg.install do
      "bash runtime.sh #{libdir}"
    end
  end
  # Nothing needed for platforms without pl-build-tools
end
