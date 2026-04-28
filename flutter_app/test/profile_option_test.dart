import 'package:flutter_app/shared/models/profile_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileOption', () {
    test('uses enum names as Firestore storage values', () {
      expect(ProfileOption.athlete.storageValue, 'athlete');
      expect(ProfileOption.coach.storageValue, 'coach');
      expect(ProfileOption.intern.storageValue, 'intern');
      expect(ProfileOption.athleteCoach.storageValue, 'athleteCoach');
      expect(ProfileOption.athleteIntern.storageValue, 'athleteIntern');
    });

    test(
      'starts pure athletes in athlete view and coach profiles in coach view',
      () {
        expect(ProfileOption.athlete.startsInCoachView, isFalse);
        expect(ProfileOption.coach.startsInCoachView, isTrue);
        expect(ProfileOption.intern.startsInCoachView, isTrue);
        expect(ProfileOption.athleteCoach.startsInCoachView, isTrue);
        expect(ProfileOption.athleteIntern.startsInCoachView, isTrue);
      },
    );

    test('allows view toggle only for hybrid profiles and admin', () {
      expect(profileTypeCanToggleView('athlete'), isFalse);
      expect(profileTypeCanToggleView('coach'), isFalse);
      expect(profileTypeCanToggleView('intern'), isFalse);
      expect(profileTypeCanToggleView('athleteCoach'), isTrue);
      expect(profileTypeCanToggleView('athleteIntern'), isTrue);
      expect(profileTypeCanToggleView('admin'), isTrue);
      expect(profileTypeCanToggleView(null), isFalse);
    });

    test(
      'identifies only athlete-coach profiles as hybrid for notifications',
      () {
        expect(profileTypeIsHybrid('athlete'), isFalse);
        expect(profileTypeIsHybrid('coach'), isFalse);
        expect(profileTypeIsHybrid('intern'), isFalse);
        expect(profileTypeIsHybrid('athleteCoach'), isTrue);
        expect(profileTypeIsHybrid('athleteIntern'), isTrue);
        expect(profileTypeIsHybrid('admin'), isFalse);
        expect(profileTypeIsHybrid(null), isFalse);
      },
    );

    test('maps stored profile strings to the correct initial view', () {
      expect(profileTypeStartsInCoachView('athlete'), isFalse);
      expect(profileTypeStartsInCoachView('coach'), isTrue);
      expect(profileTypeStartsInCoachView('intern'), isTrue);
      expect(profileTypeStartsInCoachView('athleteCoach'), isTrue);
      expect(profileTypeStartsInCoachView('athleteIntern'), isTrue);
      expect(profileTypeStartsInCoachView('admin'), isTrue);
      expect(profileTypeStartsInCoachView(null), isFalse);
    });
  });
}
