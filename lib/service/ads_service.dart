import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService {
  static Future<void> requestConsentInfoUpdate() async {
    final params = ConsentRequestParameters(
        consentDebugSettings: ConsentDebugSettings(
            debugGeography: DebugGeography.debugGeographyEea,
            testIdentifiers: ['D5E5A833CA124D2CD5E33A574AF9EA88']));

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          loadForm();
        }
      },
      (FormError error) {
        // Handle the error
      },
    );
  }

  static void loadForm() {
    ConsentForm.loadConsentForm(
      (ConsentForm consentForm) async {
        var status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          consentForm.show((formError) {
            loadForm();
          });
        }
      },
      (FormError formError) {
        // Handle the error
      },
    );
  }
}
