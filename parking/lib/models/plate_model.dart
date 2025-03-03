class Plate {
  final String plateNumber;
  final String message;

  Plate({required this.plateNumber, required this.message});

  factory Plate.fromJson(Map<String, dynamic> json) {
    return Plate(
      plateNumber: json['plateNumber'],
      message: json['message'],
    );
  }
}
