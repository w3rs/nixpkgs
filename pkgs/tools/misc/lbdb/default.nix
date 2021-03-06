{ stdenv, fetchurl, perl, perlPackages, finger_bsd, makeWrapper
, abook ? null
, gnupg ? null
, goobook ? null
, khard ? null
, mu ? null
}:

let
  version = "0.46";
in
with stdenv.lib;
with perlPackages;
stdenv.mkDerivation {
  name = "lbdb-${version}";
  src = fetchurl {
    url = "http://www.spinnaker.de/lbdb/download/lbdb_${version}.tar.gz";
    sha256 = "16fx02xk98k3friigq2lcgk535xagp3kfnmngni5kw61f7yj6gxi";
  };

  buildInputs = [ goobook makeWrapper perl ConvertASN1 NetLDAP AuthenSASL ]
    ++ optional (!stdenv.isDarwin) finger_bsd
    ++ optional   (abook != null) abook
    ++ optional   (gnupg != null) gnupg
    ++ optional (goobook != null) goobook
    ++ optional   (khard != null) khard
    ++ optional      (mu != null) mu;
  configureFlags = [ ]
    ++ optional   (abook != null) "--with-abook"
    ++ optional   (gnupg != null) "--with-gpg"
    ++ optional (goobook != null) "--with-goobook"
    ++ optional   (khard != null) "--with-khard"
    ++ optional      (mu != null) "--with-mu";

  patches = [ ./add-methods-to-rc.patch ];
  postFixup = "wrapProgram $out/lib/mutt_ldap_query --prefix PERL5LIB : "
    + "${AuthenSASL}/${perl.libPrefix}"
    + ":${ConvertASN1}/${perl.libPrefix}"
    + ":${NetLDAP}/${perl.libPrefix}";

  meta = {
    homepage = http://www.spinnaker.de/lbdb/;
    license = licenses.gpl2;
    platforms = platforms.all;
    description = "The Little Brother's Database";
    maintainers = [ maintainers.kaiha ];
  };
}
