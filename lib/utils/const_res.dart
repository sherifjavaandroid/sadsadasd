class ConstRes {
  static final String base = 'https://suplex-v2.allsafeeg-project.com/';
  static const String apiKey = 'dev123';
  static final String baseUrl = '${base}api/';

  static final String itemBaseUrl =
      'https://suplleexx.s3.eu-north-1.amazonaws.com/bubbly/';

  // Agora Credential
  static final String customerId = '42d7cb3000574fcea0a9cb993e19c946';
  static final String customerSecret = '753ab2f5fbce4b82b56c7943fd052dd4';

  // Starting screen open end_user_license_agreement sheet link
  static final String agreementUrl =
      "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";

  static final String bubblyCamera = 'bubbly_camera';
  static final bool isDialog = false;

  static void validateCredentials() {
    print('Customer ID: $customerId');
    print('Customer Secret: ${customerSecret.isNotEmpty ? '***' : 'EMPTY'}');

    if (customerId.isEmpty || customerSecret.isEmpty) {
      throw Exception('Agora credentials are missing!');
    }

    if (customerId.length != 32) {
      throw Exception('Invalid Agora App ID format');
    }

    if (customerSecret.length != 32) {
      throw Exception('Invalid Agora App Certificate format');
    }
  }
}

const String appName = 'Suplleex';
const companyName = 'All Safe';
const defaultPlaceHolderText = 'S';
const byDefaultLanguage = 'en';

const int paginationLimit = 10;

// Live broadcast Video Quality : Resolution (Width×Height)
int liveWeight = 640;
int liveHeight = 480;
int liveFrameRate = 15; //Frame rate (fps）

// Image Quality
double maxHeight = 720;
double maxWidth = 720;
int imageQuality = 100;

// max Video upload limit in MB
int maxUploadMB = 50;
// max Video upload second
int maxUploadSecond = 60;

//Strings
const List<String> paymentMethods = ['Paypal', 'Paytm', 'Other'];
const List<String> reportReasons = ['Sexual', 'Nudity', 'Religion', 'Other'];

// Video Moderation models  :- https://sightengine.com/docs/moderate-stored-video-asynchronously
String nudityModels = 'nudity,wad';
