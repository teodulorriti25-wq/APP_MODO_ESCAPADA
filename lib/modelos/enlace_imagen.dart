Uri? enlaceImagen(String? valor) {
  final texto = valor?.trim() ?? '';
  if (texto.length > 2048 || RegExp(r'[\x00-\x20\x7f\s\\]').hasMatch(texto)) {
    return null;
  }
  final uri = Uri.tryParse(texto);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.authority.contains('@')) {
    return null;
  }
  if (uri.host != 'drive.google.com') return uri;

  final archivo = RegExp(r'^/file/(?:u/\d+/)?d/([A-Za-z0-9_-]+)(?:/|$)')
      .firstMatch(uri.path);
  try {
    final parametros = uri.queryParameters;
    final id = archivo?.group(1) ??
        (const ['/open', '/uc', '/thumbnail'].contains(uri.path)
            ? parametros['id']
            : null);
    if (id == null || !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id)) return null;

    final clave = parametros['resourcekey'];
    return Uri.https('drive.google.com', '/thumbnail', {
      'id': id,
      'sz': 'w1200',
      if (clave != null && clave.isNotEmpty) 'resourcekey': clave,
    });
  } on FormatException {
    return null;
  }
}
