import 'package:flutter/material.dart';

/// APP SETTINGS INFO CONSTANTS - SECTION ///
///

/// App display name - used everywhere in the app (launcher, AppBar, dialogs).
const String APP_NAME = "Mallu cupid";

/// Brand colors - Mallu cupid rose identity.
/// DESIGN RULE: pure black is BANNED in this app (buttons, surfaces, icons,
/// text, shadows). Use the semantic palette below everywhere.
const Color APP_PRIMARY_COLOR = Color(0xFFE91E63); // rose - all primary buttons
const Color APP_PRIMARY_DARK_COLOR = Color(0xFFC2185B); // pressed states
const Color APP_ACCENT_COLOR = Color(0xFFFF6B95); // soft rose accent
const Color APP_TEXT_COLOR = Color(0xFF33303A); // charcoal plum - main text
const Color APP_TEXT_MUTED = Color(0xFF6E6875); // secondary text / appbars
const Color APP_TEXT_FAINT = Color(0xFF9A94A3); // hints / disabled
const Color APP_DIVIDER_COLOR = Color(0xFFECE7EE); // hairlines / borders
const Color APP_SHADOW_COLOR = Color(0x33512D45); // soft rose-grey shadows
const Color APP_ERROR_COLOR = Color(0xFFE5484D);
const Color APP_SUCCESS_COLOR = Color(0xFF2FA96E);

const String APP_VERSION_NAME = "v2.0.2";
const int ANDROID_APP_VERSION_NUMBER = 4; // Google Play Version Number
const int IOS_APP_VERSION_NUMBER = 2; // App Store Version Number

//
// RAZORPAY CHECKOUT (payments for Golds top-up + VIP plans)
//
// 'rzp_test_XXXXXXXX' is a TEST-MODE placeholder.
// Put your LIVE key id here when going live (Razorpay Dashboard ->
// Settings -> API Keys -> Generate Test/Live Key, format: rzp_live_xxxxxxxx).
// Without a valid key the checkout is skipped and a message is shown.
const String RAZORPAY_KEY_ID = 'rzp_test_XXXXXXXX';
// Razorpay settles in INR only.
const String RAZORPAY_CURRENCY = 'INR';

//
// GOOGLE ADMOB IDS
// Left EMPTY on purpose => ads are DISABLED everywhere in the app
// (banner/interstitial creation is guarded by isEmpty checks).
// Paste your real AdMob unit ids here to re-enable ads.
//
// For Android Platform
const String ANDROID_INTERSTITIAL_ID = "";
// For IOS Platform
const String IOS_INTERSTITIAL_ID = "";
// Banner ids
const String ANDROID_BANNER_ID = "";
const String IOS_BANNER_ID = "";

/// List of Supported Locales
/// Add your new supported Locale to the array list.
///
/// E.g: Locale('fr'), Locale('es'),
///
const List<Locale> SUPPORTED_LOCALES = [
  Locale('en'),
];
///
/// END APP SETTINGS - SECTION


///
/// DATABASE COLLECTIONS FIELD - SECTION
///
/// FIREBASE MESSAGING TOPIC
const NOTIFY_USERS = "NOTIFY_USERS";

/// DATABASE COLLECTION NAMES USED IN APP
///
const String C_APP_INFO = "AppInfo";
const String C_USERS = "Users";
const String C_FLAGGED_USERS = "FlaggedUsers";
const String C_CONNECTIONS = "Connections";
const String C_MATCHES = "Matches";
const String C_CONVERSATIONS = "Conversations";
const String C_LIKES = "Likes";
const String C_VISITS = "Visits";
const String C_DISLIKES = "Dislikes";
const String C_MESSAGES = "Messages";
const String C_NOTIFICATIONS = "Notifications";
// Payments audit collection (Razorpay transactions)
const String C_PAYMENTS = "Payments";

/// DATABASE FIELDS FOR AppInfo COLLECTION  ///
///
const String ANDROID_APP_CURRENT_VERSION = "android_app_current_version";
const String IOS_APP_CURRENT_VERSION = "ios_app_current_version";
const String ANDROID_PACKAGE_NAME = "android_package_name";
const String IOS_APP_ID = "ios_app_id";
const String APP_EMAIL = "app_email";
const String PRIVACY_POLICY_URL = "privacy_policy_url";
const String TERMS_OF_SERVICE_URL = "terms_of_service_url";
const String FIREBASE_SERVER_KEY = "firebase_server_key";
const String STORE_SUBSCRIPTION_IDS = "store_subscription_ids";
const String FREE_ACCOUNT_MAX_DISTANCE = "free_account_max_distance";
const String VIP_ACCOUNT_MAX_DISTANCE = "vip_account_max_distance";
// Admob variables
const String ADMOB_APP_ID = "admob_app_id";
const String ADMOB_INTERSTITIAL_AD_ID = "admob_interstitial_ad_id";

/// DATABASE FIELDS FOR USER COLLECTION  ///
///

//NEW
const String USER_WALLET = "user_wallet";
const String USER_ONLINE = "user_online";
const String USER_TYPING = "user_typing";
//NEW
const String USER_ID = "user_id";
const String USER_PROFILE_PHOTO = "user_photo_link";
const String USER_FULLNAME = "user_fullname";
const String USER_GENDER = "user_gender";
const String USER_BIRTH_DAY = "user_birth_day";
const String USER_BIRTH_MONTH = "user_birth_month";
const String USER_BIRTH_YEAR = "user_birth_year";
const String USER_SCHOOL = "user_school";
const String USER_JOB_TITLE = "user_job_title";
const String USER_BIO = "user_bio";
const String USER_PHONE_NUMBER = "user_phone_number";
const String USER_EMAIL = "user_email";
const String USER_GALLERY = "user_gallery";
const String USER_COUNTRY = "user_country";
const String USER_LOCALITY = "user_locality";
const String USER_GEO_POINT = "user_geo_point";
const String USER_SETTINGS = "user_settings";
const String USER_STATUS = "user_status";
const String USER_IS_VERIFIED = "user_is_verified";
const String USER_LEVEL = "user_level";
const String USER_REG_DATE = "user_reg_date";
const String USER_LAST_LOGIN = "user_last_login";
const String USER_DEVICE_TOKEN = "user_device_token";
const String USER_TOTAL_LIKES = "user_total_likes";
const String USER_TOTAL_VISITS = "user_total_visits";
const String USER_TOTAL_DISLIKED = "user_total_disliked";
// VIP subscription expiry (Timestamp) - set by PaymentsService
const String USER_VIP_UNTIL = "user_vip_until";
// User Setting map - fields
const String USER_MIN_AGE = "user_min_age";
const String USER_MAX_AGE = "user_max_age";
const String USER_MAX_DISTANCE = "user_max_distance";
const String USER_SHOW_ME = "user_show_me";


/// DATABASE FIELDS FOR FlaggedUsers COLLECTION  ///
///
const String FLAGGED_USER_ID = "flagged_user_id";
const String FLAG_REASON = "flag_reason";
const String FLAGGED_BY_USER_ID = "flagged_by_user_id";

/// DATABASE FIELDS FOR Messages and Conversations COLLECTION ///
///
const String MESSAGE_TEXT = "message_text";
const String MESSAGE_TYPE = "message_type";
const String MESSAGE_IMG_LINK = "message_img_link";
const String MESSAGE_AUDIO_LINK = "message_audio_link";
const String MESSAGE_GIF_LINK = "message_gif_link";
const String MESSAGE_STICKER_LINK = "message_sticker_link";
const String MESSAGE_READ = "message_read";
const String LAST_MESSAGE = "last_message";

/// DATABASE FIELDS FOR Notifications COLLECTION ///
///
const N_SENDER_ID = "n_sender_id";
const N_SENDER_FULLNAME = "n_sender_fullname";
const N_SENDER_PHOTO_LINK = "n_sender_photo_link";
const N_RECEIVER_ID = "n_receiver_id";
const N_TYPE = "n_type";
const N_MESSAGE = "n_message";
const N_READ = "n_read";

/// DATABASE FIELDS FOR Likes COLLECTION
///
const String LIKED_USER_ID = 'liked_user_id';
const String LIKED_BY_USER_ID = 'liked_by_user_id';
const String LIKE_TYPE = 'like_type';

/// DATABASE FIELDS FOR Dislikes COLLECTION
///
const String DISLIKED_USER_ID = 'disliked_user_id';
const String DISLIKED_BY_USER_ID = 'disliked_by_user_id';

/// DATABASE FIELDS FOR Visits COLLECTION
///
const String VISITED_USER_ID = 'visited_user_id';
const String VISITED_BY_USER_ID = 'visited_by_user_id';

/// DATABASE SHARED FIELDS FOR COLLECTION
///
const String TIMESTAMP = "timestamp";



///Remove Ads (NEW)
const bool REMOVE_ADS = true;
