import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roadcare/src/app.dart';
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
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RoadCareApp(),
      ),
    );

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
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RoadCareApp(),
      ),
    );

    container
        .read(sessionProvider.notifier)
        .signIn('officer@bidar.gov.in', UserRole.officer);
    await tester.pumpAndSettle();

    expect(find.text('MUNICIPAL OFFICER'), findsOneWidget);
    expect(find.text('Needs your action'), findsOneWidget);
    expect(find.text('Review report'), findsOneWidget);
    expect(find.text('All cases'), findsOneWidget);
    expect(find.text('Report damage'), findsNothing);
    expect(find.text('My reports'), findsNothing);
  });

  testWidgets('assigned repair team sees only its work update dashboard', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const RoadCareApp(),
      ),
    );

    container
        .read(sessionProvider.notifier)
        .signIn('team@roadcare.gov.in', UserRole.maintenance);
    await tester.pumpAndSettle();

    expect(find.text('ASSIGNED REPAIR TEAM'), findsOneWidget);
    expect(find.text('Team Shakti'), findsOneWidget);
    expect(find.text('My assigned jobs'), findsOneWidget);
    expect(find.text('Upload completion update'), findsOneWidget);
    expect(find.text('All cases'), findsNothing);
    expect(find.text('Report damage'), findsNothing);
  });

  test('municipal officer can review and approve a report', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(incidentProvider.notifier);
    const id = 'RD-1048';

    controller.transition(
      id,
      IncidentStatus.underReview,
      'Manual review started by municipal officer',
    );
    expect(
      container
          .read(incidentProvider)
          .firstWhere((item) => item.id == id)
          .status,
      IncidentStatus.underReview,
    );

    controller.transition(
      id,
      IncidentStatus.approved,
      'Case approved after manual review',
    );
    final approved = container
        .read(incidentProvider)
        .firstWhere((item) => item.id == id);
    expect(approved.status, IncidentStatus.approved);
    expect(approved.timeline.first.title, 'Case approved after manual review');
  });

  test('repair completion update retains its evidence image', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(incidentProvider.notifier);
    const id = 'RD-1047';

    controller.transition(
      id,
      IncidentStatus.awaitingClosure,
      'Completion evidence uploaded by Team Shakti',
      repairImagePath: '/demo/repaired-road.jpg',
    );

    final updated = container
        .read(incidentProvider)
        .firstWhere((item) => item.id == id);
    expect(updated.status, IncidentStatus.awaitingClosure);
    expect(updated.repairImagePath, '/demo/repaired-road.jpg');
    expect(
      updated.timeline.first.title,
      'Completion evidence uploaded by Team Shakti',
    );
  });
}
