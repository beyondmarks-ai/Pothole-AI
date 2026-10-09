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
    expect(find.text('Enter dashboard'), findsOneWidget);
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

    expect(find.text('My road reports'), findsWidgets);
    expect(find.text('Track every update'), findsOneWidget);
    expect(find.text('My reports'), findsOneWidget);
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
}
