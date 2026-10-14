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
  final List<TimelineEvent> timeline;

  RoadIncident copyWith({
    Severity? severity,
    IncidentStatus? status,
    String? assignedTeam,
    List<TimelineEvent>? timeline,
    String? repairImagePath,
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
    timeline: timeline ?? this.timeline,
  );
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
