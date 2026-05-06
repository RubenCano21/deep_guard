class UserModel {
  final String idSupabase;
  final String correo;
  final String nombreUsuario;
  final String? nombreCompleto;
  final String rol;
  final String plan;
  final String pais;
  final bool activo;
  final bool bloqueado;
  final int intentosUsados;

  UserModel({
    required this.idSupabase,
    required this.correo,
    required this.nombreUsuario,
    this.nombreCompleto,
    required this.rol,
    required this.plan,
    required this.pais,
    required this.activo,
    required this.bloqueado,
    required this.intentosUsados,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      idSupabase: json['id_supabase'] as String? ?? '',
      correo: json['correo'] as String? ?? '',
      nombreUsuario: json['nombre_usuario'] as String? ?? '',
      nombreCompleto: json['nombre_completo'] as String?,
      rol: json['rol'] as String? ?? 'usuario',
      plan: json['plan'] as String? ?? 'gratis',
      pais: json['pais'] as String? ?? 'BO',
      activo: json['activo'] as bool? ?? true,
      bloqueado: json['bloqueado'] as bool? ?? false,
      intentosUsados: json['intentos_usados'] as int? ?? 0,
    );
  }
}
