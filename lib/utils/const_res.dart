class ConstRes {
  static final String base = 'https://shortzz.retrytech.site/';
  static const String apiKey = '6vXvtsuHAGAftpcA3pTJqUJEEghQatJA';
  static final String baseUrl = '${base}api/';

  static final String itemBaseUrl = 'ITEM BASE URL';

  // Agora Credential
  static final String customerId = '2fa80f7f38ec48c7b3df029de7599738';
  static final String customerSecret = 'ce11056b3fd44851919670703656b9e9';

  // Starting screen open end_user_license_agreement sheet link
  static final String agreementUrl =
      "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/";

  static final String bubblyCamera = 'bubbly_camera';
  static final bool isDialog = false;
}

const String appName = 'Shortzz';
const companyName = 'FM_Tech';
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
