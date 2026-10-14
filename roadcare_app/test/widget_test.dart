import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roadcare/src/app.dart';
import 'package:roadcare/src/incident_api_service.dart';
import 'package:roadcare/src/models.dart';
import 'package:roadcare/src/store.dart';

void main() {
  testWidgets('shows the RoadCare sign-in experience', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: RoadCareApp()));
    await tester.pumpAndSettle();
    expect(find.text('RoadCare AI'), findsOneWidget);
    expect(find.text('Choose your role'), findsOneWidget);
    expect(find.text('Open citizen dashboard'), findsOneWidget);
  });

  testWidgets('citizen sees personal report tracking dashboard', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    await _pumpApp(tester, container);
    container
        .read(sessionProvider.notifier)
        .signIn('citizen@roadcare.app', UserRole.citizen);
    await tester.pumpAndSettle();
    expect(find.text('CITIZEN DASHBOARD'), findsOneWidget);
    expect(find.text('See a road problem?'), findsOneWidget);
    expect(find.text('My reports'), findsOneWidget);
    expect(find.text('All cases'), findsNothing);
  });

  testWidgets('municipal officer sees a separate review dashboard', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    await _pumpApp(tester, container);
    container
        .read(sessionProvider.notifier)
        .signIn('officer@bidar.gov.in', UserRole.officer);
    await tester.pumpAndSettle();
    expect(find.text('MUNICIPAL OFFICER'), findsOneWidget);
    expect(find.text('Needs your action'), findsOneWidget);
    expect(find.text('Review report'), findsOneWidget);
    expect(find.text('All cases'), findsOneWidget);
    expect(find.text('Report damage'), findsNothing);
  });

  testWidgets('assigned repair team sees only its work update dashboard', (
    tester,
  ) async {
    final container = _container();
    addTearDown(container.dispose);
    await _pumpApp(tester, container);
    container
        .read(sessionProvider.notifier)
        .signIn('team@roadcare.gov.in', UserRole.maintenance);
    await tester.pumpAndSettle();
    expect(find.text('ASSIGNED REPAIR TEAM'), findsOneWidget);
    expect(find.text('Team Shakti'), findsOneWidget);
    expect(find.text('My assigned jobs'), findsOneWidget);
    expect(find.text('Upload completion update'), findsOneWidget);
    expect(find.text('All cases'), findsNothing);
  });

  test('municipal officer can review and approve a cloud report', () async {
    final container = _container();
    addTearDown(container.dispose);
    container
        .read(sessionProvider.notifier)
        .signIn('officer@bidar.gov.in', UserRole.officer);
    final controller = container.read(incidentProvider.notifier);
    await controller.refresh();
    await controller.transition(
      'RD-1048',
      IncidentStatus.underReview,
      'Manual review started by municipal officer',
    );
    expect(
      container
          .read(incidentProvider)
          .firstWhere((item) => item.id == 'RD-1048')
          .status,
      IncidentStatus.underReview,
    );
    await controller.transition(
      'RD-1048',
      IncidentStatus.approved,
      'Case approved after manual review',
    );
    final approved = container
        .read(incidentProvider)
        .firstWhere((item) => item.id == 'RD-1048');
    expect(approved.status, IncidentStatus.approved);
    expect(approved.timeline.first.title, 'Case approved after manual review');
  });

  test('repair completion update retains its evidence image', () async {
    final container = _container();
    addTearDown(container.dispose);
    container
        .read(sessionProvider.notifier)
        .signIn('team@roadcare.gov.in', UserRole.maintenance);
    final controller = container.read(incidentProvider.notifier);
    await controller.refresh();
    await controller.transition(
      'RD-1047',
      IncidentStatus.awaitingClosure,
      'Completion evidence uploaded by Team Shakti',
      repairImagePath: '/demo/repaired-road.jpg',
    );
    final updated = container
        .read(incidentProvider)
        .firstWhere((item) => item.id == 'RD-1047');
    expect(updated.status, IncidentStatus.awaitingClosure);
    expect(updated.repairImagePath, '/demo/repaired-road.jpg');
    expect(
      updated.timeline.first.title,
      'Completion evidence uploaded by Team Shakti',
    );
  });
}

ProviderContainer _container() => ProviderContainer(
  overrides: [incidentApiProvider.overrideWithValue(_FakeIncidentApi())],
);

Future<void> _pumpApp(WidgetTester tester, ProviderContainer container) =>
    tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RoadCareApp(),
      ),
    );

class _FakeIncidentApi implements IncidentApi {
  final List<RoadIncident> _items = [_incident(), _incident(assigned: true)];

  @override
  Future<List<RoadIncident>> fetch(AppUser user) async => switch (user.role) {
    UserRole.citizen =>
      _items.where((item) => item.reporterEmail == user.email).toList(),
    UserRole.maintenance =>
      _items.where((item) => item.assignedTeam == user.name).toList(),
    _ => List.of(_items),
  };

  @override
  Future<RoadIncident> create(RoadIncident incident) async {
    _items.insert(0, incident);
    return incident;
  }

  @override
  Future<RoadIncident> update(RoadIncident incident) async {
    final index = _items.indexWhere((item) => item.id == incident.id);
    _items[index] = incident;
    return incident;
  }
}

RoadIncident _incident({bool assigned = false}) {
  final now = DateTime.utc(2026, 10, 14);
  return RoadIncident(
    id: assigned ? 'RD-1047' : 'RD-1048',
    roadName: assigned ? 'Station Road' : 'Ring Road',
    area: 'Bidar, Karnataka',
    type: DamageType.pothole,
    severity: Severity.high,
    status: assigned
        ? IncidentStatus.inProgress
        : IncidentStatus.pendingVerification,
    confidence: .94,
    latitude: 17.9133,
    longitude: 77.5301,
    reportedAt: now,
    priorityScore: 88,
    healthScore: 36,
    description: 'Road damage reported by a citizen.',
    reporterName: 'Rahul Patil',
    reporterEmail: 'citizen@roadcare.app',
    assignedTeam: assigned ? 'Team Shakti' : null,
    timeline: [
      TimelineEvent(title: 'Report received', detail: 'Uploaded', time: now),
    ],
  );
}
