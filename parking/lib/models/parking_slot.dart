class ParkingSlot {
  final String id;
  final bool isAvailable;
  final String level;

  ParkingSlot({required this.id, required this.isAvailable, required this.level});

  factory ParkingSlot.fromJson(Map<String, dynamic> json) {
    return ParkingSlot(
      id: json['id'],
      isAvailable: json['isAvailable'],
      level: json['level'] ?? "Desconocido",
    );
  }
}
