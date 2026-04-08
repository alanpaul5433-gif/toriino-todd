class AvailabilityModel {
  final String? mentorId;
  final String? slotId;
  final String? dayOfWeek;
  final String? startTime;
  final String? endTime;
  final bool? isRecurring;
  final String? date;

  AvailabilityModel({
    this.mentorId,
    this.slotId,
    this.dayOfWeek,
    this.startTime,
    this.endTime,
    this.isRecurring,
    this.date,
  });

  factory AvailabilityModel.fromJson(Map<String, dynamic> json) {
    return AvailabilityModel(
      mentorId: json['mentorId'],
      slotId: json['slotId'],
      dayOfWeek: json['dayOfWeek'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      isRecurring: json['isRecurring'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'isRecurring': isRecurring ?? true,
      'date': date,
    };
  }
}
