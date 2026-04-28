enum ProfileOption { athlete, coach, intern, athleteCoach, athleteIntern }

extension ProfileOptionX on ProfileOption {
  String get storageValue => name;

  bool get startsInCoachView {
    return this == ProfileOption.coach ||
        this == ProfileOption.intern ||
        this == ProfileOption.athleteCoach ||
        this == ProfileOption.athleteIntern;
  }
}

bool profileTypeCanToggleView(String? profileType) {
  return profileType == ProfileOption.athleteCoach.storageValue ||
      profileType == ProfileOption.athleteIntern.storageValue ||
      profileType == 'admin';
}

bool profileTypeIsHybrid(String? profileType) {
  return profileType == ProfileOption.athleteCoach.storageValue ||
      profileType == ProfileOption.athleteIntern.storageValue;
}

bool profileTypeStartsInCoachView(String? profileType) {
  return profileType == ProfileOption.coach.storageValue ||
      profileType == ProfileOption.intern.storageValue ||
      profileType == ProfileOption.athleteCoach.storageValue ||
      profileType == ProfileOption.athleteIntern.storageValue ||
      profileType == 'admin';
}
