enum UserRole { citizen, officer, maintenance, administrator }

enum DamageType { pothole, longitudinalCrack, transverseCrack, alligatorCrack }

enum Severity { low, medium, high, critical }

enum IncidentStatus {
  pendingVerification,
  underReview,
  approved,
  assigned,
  inProgress,
  awaitingClosure,
  closed,
  rejected,
}

class AppUser {
  const AppUser({required this.name, required this.email, required this.role});
  final String name;
  final String email;
  final UserRole role;
}

class TimelineEvent {
  const TimelineEvent({
    required this.title,
    required this.detail,
    required this.time,
  });
  final String title;
  final String detail;
  final DateTime time;

  factory TimelineEvent.fromJson(Map<String, dynamic> json) => TimelineEvent(
    title: json['title'] as String? ?? 'Status updated',
    detail: json['detail'] as String? ?? '',
    time: DateTime.parse(json['time'] as String),
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'detail': detail,
    'time': time.toUtc().toIso8601String(),
  };
}

class RoadIncident {
  const RoadIncident({
    required this.id,
    required this.roadName,
    required this.area,
    required this.type,
    required this.severity,
    required this.status,
    required this.confidence,
    required this.latitude,
    required this.longitude,
    required this.reportedAt,
    required this.priorityScore,
    required this.healthScore,
    required this.description,
    required this.reporterName,
    required this.reporterEmail,
    required this.assignedTeam,
    required this.timeline,
    this.imagePath,
    this.repairImagePath,
    this.imageUrl,
    this.repairImageUrl,
  });
  final String id;
  final String roadName;
  final String area;
  final DamageType type;
  final Severity severity;
  final IncidentStatus status;
  final double confidence;
  final double latitude;
  final double longitude;
  final DateTime reportedAt;
  final int priorityScore;
  final int healthScore;
  final String description;
  final String reporterName;
  final String reporterEmail;
  final String? assignedTeam;
  final String? imagePath;
  final String? repairImagePath;
  final String? imageUrl;
  final String? repairImageUrl;
  final List<TimelineEvent> timeline;

  RoadIncident copyWith({
    Severity? severity,
    IncidentStatus? status,
    String? assignedTeam,
    List<TimelineEvent>? timeline,
    String? repairImagePath,
    String? imageUrl,
    String? repairImageUrl,
  }) => RoadIncident(
    id: id,
    roadName: roadName,
    area: area,
    type: type,
    severity: severity ?? this.severity,
    status: status ?? this.status,
    confidence: confidence,
    latitude: latitude,
    longitude: longitude,
    reportedAt: reportedAt,
    priorityScore: priorityScore,
    healthScore: healthScore,
    description: description,
    reporterName: reporterName,
    reporterEmail: reporterEmail,
    assignedTeam: assignedTeam ?? this.assignedTeam,
    imagePath: imagePath,
    repairImagePath: repairImagePath ?? this.repairImagePath,
    imageUrl: imageUrl ?? this.imageUrl,
    repairImageUrl: repairImageUrl ?? this.repairImageUrl,
    timeline: timeline ?? this.timeline,
  );

  factory RoadIncident.fromJson(Map<String, dynamic> json) => RoadIncident(
    id: json['id'] as String,
    roadName: json['roadName'] as String,
    area: json['area'] as String,
    type: DamageType.values.byName(json['type'] as String),
    severity: Severity.values.byName(json['severity'] as String),
    status: IncidentStatus.values.byName(json['status'] as String),
    confidence: (json['confidence'] as num).toDouble(),
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
    reportedAt: DateTime.parse(json['reportedAt'] as String),
    priorityScore: (json['priorityScore'] as num).round(),
    healthScore: (json['healthScore'] as num).round(),
    description: json['description'] as String,
    reporterName: json['reporterName'] as String,
    reporterEmail: json['reporterEmail'] as String,
    assignedTeam: json['assignedTeam'] as String?,
    imageUrl: json['imageUrl'] as String?,
    repairImageUrl: json['repairImageUrl'] as String?,
    timeline: (json['timeline'] as List<dynamic>)
        .map((item) => TimelineEvent.fromJson(item as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'roadName': roadName,
    'area': area,
    'type': type.name,
    'severity': severity.name,
    'status': status.name,
    'confidence': confidence,
    'latitude': latitude,
    'longitude': longitude,
    'reportedAt': reportedAt.toUtc().toIso8601String(),
    'priorityScore': priorityScore,
    'healthScore': healthScore,
    'description': description,
    'reporterName': reporterName,
    'reporterEmail': reporterEmail,
    'assignedTeam': assignedTeam,
    'imageUrl': imageUrl,
    'repairImageUrl': repairImageUrl,
    'timeline': timeline.map((event) => event.toJson()).toList(),
  };
}

extension Labels on Object {
  String get label {
    if (this is DamageType) {
      return switch (this as DamageType) {
        DamageType.pothole => 'Pothole',
        DamageType.longitudinalCrack => 'Longitudinal crack',
        DamageType.transverseCrack => 'Transverse crack',
        DamageType.alligatorCrack => 'Alligator crack',
      };
    }
    if (this is Severity) {
      return switch (this as Severity) {
        Severity.low => 'Low',
        Severity.medium => 'Medium',
        Severity.high => 'High',
        Severity.critical => 'Critical',
      };
    }
    if (this is IncidentStatus) {
      return switch (this as IncidentStatus) {
        IncidentStatus.pendingVerification => 'Pending review',
        IncidentStatus.underReview => 'Manual review',
        IncidentStatus.approved => 'Approved',
        IncidentStatus.assigned => 'Assigned',
        IncidentStatus.inProgress => 'In progress',
        IncidentStatus.awaitingClosure => 'Awaiting closure',
        IncidentStatus.closed => 'Closed',
        IncidentStatus.rejected => 'Rejected',
      };
    }
    if (this is UserRole) {
      return switch (this as UserRole) {
        UserRole.citizen => 'Citizen reporter',
        UserRole.officer => 'Municipal officer',
        UserRole.maintenance => 'Maintenance team',
        UserRole.administrator => 'Administrator',
      };
    }
    return toString();
  }
}
