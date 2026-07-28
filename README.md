<div align="center">
<br/>
<img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
<img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" />
<img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
<img src="https://img.shields.io/badge/Cloudinary-3448C5?style=for-the-badge&logo=cloudinary&logoColor=white" />
<img src="https://img.shields.io/badge/OneSignal-E54A4A?style=for-the-badge&logo=onesignal&logoColor=white" />
<br/><br/>
</div>

# To-Let BD - Find Your Next Home

A location-first Flutter marketplace built with Provider and a clean MVC architecture for discovering and listing rental properties across Bangladesh — powered by a comprehensive **Division → District → Thana → Area** geo-hierarchy, with real-time chat, interest tracking, and push notifications, all in one app.

---

## Features

**Authentication & Onboarding**
- Email/password registration and login with Firebase Authentication
- Mandatory email verification screen that auto-polls every 3 seconds and also re-checks on app resume
- Resend verification email and forgot-password (email reset link) flows
- First-run **Set Location** step (skippable) right after verification, before reaching the home feed

**Bangladesh Location System**
- Full offline Division → District → Thana dataset bundled as JSON, loaded once and cached in memory
- Cascading pickers: choosing a Division filters Districts, choosing a District filters Thanas
- Normalized, hierarchical **area search key** (`division_district_thana_area`) used to index every listing for fast prefix search
- Autocomplete **Area** field with debounced Firestore prefix search while creating a post
- Area **picker** in Search that only shows areas that actually have existing posts in that Thana, with a "No Area Found" state
- Users can set/update their own location anytime from the Home header

**Home Feed**
- Property-type filter chips (Family Flat, Bachelor Flat, Bachelor Room, Bachelor Seat, Shop, Studio)
- **Best For You** horizontal rail — posts matched to the user's saved area first, then nearby posts in the same Thana, excluding their own listings
- Recent Posts grid with pull-to-refresh
- Animated bottom navigation bar that hides on scroll-down and reappears on scroll-up (Home tab only)

**Search**
- Keyword search by title, combined with property type, rent range, and full location filters
- Available-from date range filtering (earliest / latest)
- Area picker wired to real listing availability per Thana
- One-tap **Reset** to clear every filter

**Create & Edit Post**
- Property type, title, rich description, rent, bedrooms, bathrooms
- Multi-select facilities (Lift, Generator, Gas, Parking, CCTV, Security Guard, Water Reserve Tank, Balcony, Furnished)
- Available-from date picker
- Multi-image picker with in-form preview grid and per-image removal
- Images uploaded to Cloudinary on publish; edit mode tracks existing vs newly-added images and deletes removed ones from Cloudinary on save
- Auto-registers the post's area in the global area index for search/autocomplete

**Post Detail**
- Full-bleed image carousel with page indicator, dot indicator, and a full-screen pinch-to-zoom viewer
- "Rented" ribbon badge when a listing is no longer active
- Owner tools: Edit, Delete (with confirmation, cascades cleanup of interests/notifications/chats), Mark as Rented / Mark as Available
- Owner can view an **Interested People** list per post and start a chat directly from it
- Seeker tools: toggle **Interested**, open direct chat with the owner
- Deep-linked entry from push notifications, with a custom back-to-home behavior

**Real-Time Chat**
- One conversation thread per owner–seeker–post combination
- Text messages plus multi-image sharing via Cloudinary, rendered as inline thumbnails with a full-screen viewer
- Sticky post-preview header inside the conversation, linking back to the listing
- Automatic system banners inside the thread when the linked post is marked **Rented** or **Available** again
- Messaging is permanently locked (with a "post deleted" placeholder) if the listing is removed
- Chat list with unread badges, "N new messages" grouping, photo-message indicator, and last-message timestamps (Today / Yesterday / date)

**Notifications**
- In-app notification center for: someone is interested in your post, your interested post was marked Rented, and a previously-rented post became Available again
- Unread-count badges on the bottom nav and Profile menu, powered by Firestore streams
- Tap-through navigation straight into the relevant chat or post

**Push Notifications (OneSignal)**
- OneSignal external-ID login/logout tied to the Firebase Auth session
- Server-side push fired the moment someone shows interest, or a post's rented status changes
- Cold-start deep links: tapping a push notification opens the exact post, even before the app has finished its own launch/auth check

**Profile**
- Name, email, and phone summary card
- **My Posts**, **Interested Posts**, and **Notifications** shortcuts with live badge counts
- Logout with confirmation dialog

---

## Screenshots

### Auth
<table>
  <tr>
    <td align="center"><img src="app screenshots/1 auth/1.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/1 auth/2.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/1 auth/3.jpg" width="220"/></td>
  </tr>
</table>

### Set & Update Location
<table>
  <tr>
    <td align="center"><img src="app screenshots/2 set and update locations/4.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/2 set and update locations/5.jpg" width="220"/></td>
    <td></td>
  </tr>
</table>

### Home
<table>
  <tr>
    <td align="center"><img src="app screenshots/3 home/6.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/3 home/7.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/3 home/8.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/3 home/9.jpg" width="220"/></td>
    <td></td>
    <td></td>
  </tr>
</table>

### Create / Edit Post
<table>
  <tr>
    <td align="center"><img src="app screenshots/4 create edit post/10.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/4 create edit post/11.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/4 create edit post/12.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/4 create edit post/13.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/4 create edit post/14.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/4 create edit post/15.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/4 create edit post/16.jpg" width="220"/></td>
    <td></td>
    <td></td>
  </tr>
</table>

### My Posts & Post Details
<table>
  <tr>
    <td align="center"><img src="app screenshots/5 my posts and post detail screen/17.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/5 my posts and post detail screen/18.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/5 my posts and post detail screen/19.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/5 my posts and post detail screen/20.jpg" width="220"/></td>
    <td></td>
    <td></td>
  </tr>
</table>

### Rented & Available Status
<table>
  <tr>
    <td align="center"><img src="app screenshots/6 rented and available status/21.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/6 rented and available status/22.jpg" width="220"/></td>
    <td></td>
  </tr>
</table>

### Search
<table>
  <tr>
    <td align="center"><img src="app screenshots/7 search/23.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/7 search/24.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/7 search/25.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/7 search/26.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/7 search/27.jpg" width="220"/></td>
    <td></td>
  </tr>
</table>

### Notifications & Alerts
<table>
  <tr>
    <td align="center"><img src="app screenshots/8 notifications and alerts/28.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/8 notifications and alerts/29.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/8 notifications and alerts/30.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/8 notifications and alerts/31a.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/8 notifications and alerts/32.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/8 notifications and alerts/33.jpg" width="220"/></td>
  </tr>
</table>

### Interested Posts
<table>
  <tr>
    <td align="center"><img src="app screenshots/9 Interested posts/34.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/9 Interested posts/35.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/9 Interested posts/36.jpg" width="220"/></td>
  </tr>
</table>

### Messages
<table>
  <tr>
    <td align="center"><img src="app screenshots/10 messages/37.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/10 messages/38.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/10 messages/39.jpg" width="220"/></td>
  </tr>
  <tr>
    <td align="center"><img src="app screenshots/10 messages/40.jpg" width="220"/></td>
    <td align="center"><img src="app screenshots/10 messages/41.jpg" width="220"/></td>
    <td></td>
  </tr>
</table>

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| State Management | Provider (`ChangeNotifier` controllers per screen) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Image Storage | Cloudinary (unsigned uploads) |
| Push Notifications | OneSignal |
| Location Data | Bundled offline Division/District/Thana JSON dataset |
| Utilities | intl (date formatting) |
| File & Image Handling | image_picker |

---

## Architecture

```
lib/
├── main.dart                          # App entry, MultiProvider, theme, OneSignal
│                                      #   click listener & deep-link routing
├── firebase_options.dart
├── models/
│   ├── post_model.dart                # PostModel, PostImage
│   ├── chat_model.dart                # ChatModel, MessageModel
│   ├── notification_model.dart        # NotificationModel
│   └── user_location_model.dart       # UserLocationModel
├── services/
│   ├── auth_service.dart              # Sign up/in/out, verification, reset
│   ├── firestore_service.dart         # All Firestore reads/writes/streams
│   ├── cloudinary_service.dart        # Image upload/delete
│   ├── location_service.dart          # Geo dataset, search-key builder
│   └── notification_service.dart      # OneSignal init + push senders
├── utils/
│   └── constants.dart                 # AppColors, AppTextStyles, enums
├── widgets/
│   ├── area_search_field.dart         # Debounced area autocomplete (Create/Edit)
│   ├── area_picker_field.dart         # Area picker restricted to real listings (Search)
│   ├── location_picker_field.dart     # Division/District/Thana bottom-sheet picker
│   └── post_card.dart                 # Grid card used across Home/Search/My Posts
└── screens/
    ├── splash_screen.dart             # Auth check + pending-notification handoff
    ├── auth/
    │   ├── login_screen.dart
    │   ├── signup_screen.dart
    │   └── verify_email_screen.dart   # Auto-polling verification
    ├── location/
    │   └── set_location_screen.dart   # First-run + update-location flow
    ├── home/
    │   ├── main_screen.dart           # Bottom nav shell (Home/Search/Chat/Profile)
    │   ├── home_screen.dart           # Feed, chips, Best For You
    │   └── best_for_you_screen.dart
    ├── search/
    │   └── search_screen.dart
    ├── post/
    │   ├── create_post_screen.dart
    │   ├── edit_post_screen.dart
    │   ├── post_detail_screen.dart
    │   ├── my_posts_screen.dart
    │   ├── interested_posts_screen.dart
    │   └── full_screen_image_viewer.dart
    ├── chat/
    │   ├── chat_list_screen.dart
    │   └── chat_conversation_screen.dart
    ├── notifications/
    │   └── notifications_screen.dart
    └── profile/
        └── profile_screen.dart

controllers/                           # One ChangeNotifier controller per screen
├── auth/auth_controller.dart
├── home/home_controller.dart
├── location/set_location_screen_controller.dart
├── post/create_post_screen_controller.dart
├── post/edit_post_screen_controller.dart
├── post/post_detail_screen_controller.dart
├── post/my_posts_screen_controller.dart
├── post/interested_posts_screen_controller.dart
├── search/search_screen_controller.dart
├── chat/chat_list_screen_controller.dart
├── chat/chat_conversation_screen_controller.dart
├── notifications/notifications_screen_controller.dart
└── profile/profile_screen_controller.dart
```

**Auth & Onboarding Flow**
```
App Launch
    └── SplashScreen checks FirebaseAuth current user
            ├── No user           →  LoginScreen
            ├── Not verified      →  VerifyEmailScreen (polls every 3s + on resume)
            └── Verified
                    └── SetLocationScreen (first run, skippable)
                            └── MainScreen (Home / Search / Chat / Profile)
```

**Area Indexing & Search**
```
Owner fills Division / District / Thana / Area on Create Post
    └── LocationService.buildAreaSearchKey()
            → "division_district_thana_area" (normalized, lowercase)
    └── FirestoreService.ensureAreaExists()
            → upserts a doc in /areas keyed by the search key
    └── Post saved with `areaSearchKey` for prefix-range queries

Search / Best-For-You
    └── Exact areaSearchKey match first
    └── Prefix range query on "division_district_thana_" for nearby results
```

**Interest → Notification → Push Flow**
```
Seeker taps "Interested"
    └── FirestoreService.addInterest()
            ├── writes /posts/{id}/interested/{seekerUid}
            ├── increments post.interestedCount
            └── writes /notifications/{ownerUid}/items/{postId_seekerUid}
    └── NotificationService.sendInterestedNotification()  → OneSignal push to owner

Owner marks post Rented / Available
    └── FirestoreService.markPostRented() / markPostAvailable()
            ├── updates post status
            ├── writes a notification for every interested seeker
            └── flips chat.messagingEnabled + posts a status-change banner
    └── NotificationService.sendPostRentedNotification() / sendRentAvailableNotification()
```

**Chat Media Flow**
```
User picks image(s) in a conversation
    └── CloudinaryService.uploadImage() per file
    └── FirestoreService.sendMessage(imageUrl: ...)
            ├── writes the message doc
            └── updates chat.lastMessage ("📷 Photo") + unread counter for the other participant
```

---

## Getting Started

### Prerequisites
- Flutter SDK ≥ 3.x
- A Firebase project with **Authentication** (Email/Password) and **Cloud Firestore** enabled
- A [Cloudinary](https://cloudinary.com) account with an **unsigned upload preset**
- A [OneSignal](https://onesignal.com) app configured for push notifications

### Setup

1. **Clone the repository**
```bash
git clone https://github.com/TanvirAhmedCSE/to-let-bd-find-your-next-home.git
cd to-let-bd-find-your-next-home
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Firebase setup**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Enable **Email/Password** authentication
   - Enable **Cloud Firestore**
   - Download `google-services.json` (Android) and/or `GoogleService-Info.plist` (iOS) and place them in the correct platform directories
   - Run `flutterfire configure` or add your own `firebase_options.dart`

4. **Location dataset**
   - Ensure `assets/data/divisions.json`, `assets/data/districts.json`, and `assets/data/upazilas.json` are present (bundled with the repo) and declared under `assets:` in `pubspec.yaml`

5. **Cloudinary setup**
   - Create a Cloudinary account and note your **Cloud Name**
   - Create an **unsigned upload preset**
   - Set `cloudName`, `uploadPreset`, `apiKey`, and `apiSecret` in `lib/utils/constants.dart` (`CloudinaryConfig`)

6. **OneSignal setup**
   - Create a OneSignal app
   - Set the app ID and REST API key in `lib/services/notification_service.dart`

7. **Run the app**
```bash
flutter run
```

---

## Firestore Security Rules

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
      match /interestedPosts/{postId} {
        allow read, create, update: if request.auth.uid == uid;
        allow delete: if request.auth != null &&
          (request.auth.uid == uid ||
           (resource != null && request.auth.uid == resource.data.uploaderUid));
      }
    }
    match /posts/{postId} {
      allow read: if true;
      allow create: if request.auth != null;
      allow delete: if request.auth.uid == resource.data.uploaderUid;
      allow update: if request.auth != null && (
        request.auth.uid == resource.data.uploaderUid ||
        request.resource.data.diff(resource.data).affectedKeys().hasOnly(['interestedCount'])
      );
      match /interested/{seekerUid} {
        allow read: if request.auth != null;
        allow create: if request.auth.uid == seekerUid;
        allow delete: if request.auth != null &&
          (request.auth.uid == seekerUid ||
           (resource != null && request.auth.uid == resource.data.uploaderUid));
      }
    }
    match /areas/{areaId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /notifications/{uid}/items/{notifId} {
      allow create, update: if request.auth != null;
      allow read: if request.auth != null && request.auth.uid == uid;
      allow delete: if request.auth != null &&
        (request.auth.uid == uid ||
         resource == null ||
          (resource != null && request.auth.uid == resource.data.fromUid));
    }
    match /chats/{chatId} {
      allow read: if request.auth != null &&
        (resource == null || request.auth.uid in resource.data.participants);
      allow create: if request.auth != null &&
        request.auth.uid in request.resource.data.participants;
      allow update: if request.auth != null &&
        request.auth.uid in resource.data.participants;
      allow delete: if false;
      match /messages/{messageId} {
        allow read, write: if request.auth != null;
      }
    }
  }
}
```

---

## Key Dependencies

```yaml
# Firebase
firebase_core: ^4.0.0
firebase_auth: ^6.0.0
cloud_firestore: ^6.0.0

# Networking / Cloudinary upload
http: ^1.5.0
crypto: ^3.0.6

# Image picking
image_picker: ^1.2.0

# Date formatting
intl: ^0.20.2

# State management
provider: ^6.1.5+1

# Push notifications
onesignal_flutter: ^5.6.0
```

---

## Security Notes

- Firebase credentials (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) are **not included** in this repository. Configure your own Firebase project before running.
- The `CloudinaryConfig` and OneSignal app ID / REST API key in this repo are placeholders — replace them with your own before running.
- The OneSignal REST API key is currently called directly from the client for simplicity. For production, move push-sending behind a Cloud Function so the REST API key is never bundled in the app.
- Firestore rules above are suitable for development. For production, tighten them to validate ownership per document (e.g. only the post owner can update/delete their own post, only chat participants can read a given chat).

---

## License

This project is open-source and available under the [MIT License](LICENSE).

---

<div align="center">
Made with ❤️ and Flutter

*If you find this project useful, please give it a ⭐ on GitHub!*
</div>
