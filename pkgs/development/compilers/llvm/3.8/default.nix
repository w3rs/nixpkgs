{ newScope, stdenv, libstdcxxHook, isl, fetchurl, overrideCC, wrapCCWith, darwin
, buildLlvmPackages # ourself, but from the previous stage, for cross
, targetLlvmPackages # ourself, but from the next stage, for cross
}:

let
  callPackage = newScope (self // { inherit stdenv isl version fetch; });

  version = "3.8.1";

  fetch = fetch_v version;
  fetch_v = ver: name: sha256: fetchurl {
    url = "http://llvm.org/releases/${ver}/${name}-${ver}.src.tar.xz";
    inherit sha256;
  };

  compiler-rt_src = fetch "compiler-rt" "0p0y85c7izndbpg2l816z7z7558axq11d5pwkm4h11sdw7d13w0d";
  clang-tools-extra_src = fetch "clang-tools-extra" "15n39r4ssphpaq4a0wzyjm7ilwxb0bch6nrapy8c5s8d49h5qjk6";

  self = {
    llvm = callPackage ./llvm.nix {
      inherit compiler-rt_src stdenv;
    };

    clang-unwrapped = callPackage ./clang {
      inherit clang-tools-extra_src stdenv;
    };

    libclang = self.clang-unwrapped.lib;

    clang = if stdenv.cc.isGNU then self.libstdcxxClang else self.libcxxClang;

    libstdcxxClang = wrapCCWith {
      cc = self.clang-unwrapped;
      extraPackages = [ libstdcxxHook ];
    };

    libcxxClang = wrapCCWith {
      cc = self.clang-unwrapped;
      extraPackages = [ targetLlvmPackages.libcxx targetLlvmPackages.libcxxabi ];
    };

    stdenv = stdenv.override (drv: {
      allowedRequisites = null;
      cc = self.clang;
    });

    libcxxStdenv = stdenv.override (drv: {
      allowedRequisites = null;
      cc = buildLlvmPackages.libcxxClang;
    });

    lldb = callPackage ./lldb.nix {};

    libcxx = callPackage ./libc++ {};

    libcxxabi = callPackage ./libc++abi.nix {};
  };
in self
