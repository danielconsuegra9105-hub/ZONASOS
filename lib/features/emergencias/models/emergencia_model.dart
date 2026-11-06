class EmergenciaModel {
  final String id;
  final String tipo;
  final String descripcion;
  final double lat;
  final double lng;
  final DateTime fecha;
  String estado;

  EmergenciaModel({
    required this.id,
    required this.tipo,
    required this.descripcion,
    required this.lat,
    required this.lng,
    required this.fecha,
    this.estado = 'PENDIENTE',
  });

  Map<String, dynamic> toJson() => {
        'id': id.isEmpty ? null : id,
        'titulo': tipo,
        'descripcion': descripcion,
        'latitud': lat,
        'longitud': lng,
        'ubicacionTexto': 'Cartagena, Colombia',
        'estado': estado,
      };

  factory EmergenciaModel.fromJson(Map<String, dynamic> json) {
    return EmergenciaModel(
      id: json['id'] ?? '',
      tipo: json['titulo'] ?? json['tipo'] ?? 'Emergencia',
      descripcion: json['descripcion'] ?? '',
      lat: (json['latitud'] ?? json['lat'] ?? 10.39972).toDouble(),
      lng: (json['longitud'] ?? json['lng'] ?? -75.51444).toDouble(),
      fecha: json['fechaHoraCreacion'] != null 
          ? DateTime.parse(json['fechaHoraCreacion']) 
          : DateTime.now(),
      estado: json['estado'] ?? 'PENDIENTE',
    );
  }
}