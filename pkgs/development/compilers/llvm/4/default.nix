{ lowPrio, newScope, stdenv, targetPlatform, cmake, libstdcxxHook
, libxml2, python2, isl, fetchurl, overrideCC, wrapCCWith
, darwin
, buildLlvmPackages # ourself, but from the previous stage, for cross
, targetLlvmPackages # ourself, but from the next stage, for cross
}:

let
  callPackage = newScope (self // { inherit stdenv cmake libxml2 python2 isl release_version version fetch; });

  release_version = "4.0.1";
  version = release_version; # differentiating these is important for rc's

  fetch = name: sha256: fetchurl {
    url = "https://releases.llvm.org/${release_version}/${name}-${version}.src.tar.xz";
    inherit sha256;
  };

  compiler-rt_src = fetch "compiler-rt" "0h5lpv1z554szi4r4blbskhwrkd78ir50v3ng8xvk1s86fa7gj53";
  clang-tools-extra_src = fetch "clang-tools-extra" "1dhmp7ccfpr42bmvk3kp37ngjpf3a9m5d4kkpsn7d00hzi7fdl9m";

  # Add man output without introducing extra dependencies.
  overrideManOutput = drv:
    let drv-manpages = drv.override { enableManpages = true; }; in
    drv // { man = drv-manpages.out; /*outputs = drv.outputs ++ ["man"];*/ };

  llvm = callPackage ./llvm.nix {
    inherit compiler-rt_src stdenv;
  };

  clang-unwrapped = callPackage ./clang {
    inherit clang-tools-extra_src stdenv;
  };

  self = {
    llvm = overrideManOutput llvm;
    clang-unwrapped = overrideManOutput clang-unwrapped;

    libclang = self.clang-unwrapped.lib;
    llvm-manpages = lowPrio self.llvm.man;
    clang-manpages = lowPrio self.clang-unwrapped.man;

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

    lld = callPackage ./lld.nix {};

    lldb = callPackage ./lldb.nix {};

    libcxx = callPackage ./libc++ {};

    libcxxabi = callPackage ./libc++abi.nix {};

    openmp = callPackage ./openmp.nix {};
  };

in self
