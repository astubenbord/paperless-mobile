enum OsErrorCodes {
  serverUnreachable(101),
  hostNotFound(7),
  invalidClientCertConfig(318767212);

  const OsErrorCodes(this.code);
  final int code;
}
