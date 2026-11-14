# DocuTrack

DocuTrack is a Flutter student document-request app backed by Firebase
Authentication and Cloud Firestore. It uses the existing
`lib/firebase_options.dart` generated for this project; the app code does not
replace or edit those Firebase options.

## Firebase setup

1. In Firebase Console, enable **Authentication → Sign-in method → Email/Password**.
2. Create a Cloud Firestore database.
3. Publish the rules in [`firestore.rules`](./firestore.rules). The rules keep
   student profiles private, prevent students from assigning themselves the
   admin role, limit students to their own requests, and restrict management
   actions to admins.
   Deploy the Firestore indexes in [`firestore.indexes.json`](./firestore.indexes.json)
   as well; student request lists combine an owner filter with created-date
   ordering.
4. Create the first administrator:
   - Create that account under **Authentication → Users**.
   - Copy its Firebase Auth UID.
   - In Firestore, create `users/{UID}` with fields:
     `name` (string), `email` (string), `studentId` (string), `program`
     (string), `role` (string set to `admin`), `active` (boolean set to `true`),
     and `createdAt` / `updatedAt` (timestamps).
5. Sign in to DocuTrack with that administrator account. Open **Documents** and
   choose **Add standard document types** to publish Enrollment Form, Good Moral
   Certificate, TOR, and other common requests. Use **Students** to create
   student accounts, or let students register themselves in the app.

The first admin is assigned in the Firebase Console intentionally. A public
sign-up form must never be allowed to grant admin privileges.

## Run

```powershell
flutter pub get
flutter run
```

The app signs students into the student screens and routes admin profiles to
the administration screens based on their Firestore profile.

Admin screens are grouped separately in `lib/screens/Admin/`:

- `admin_shell.dart` — responsive admin navigation and overview.
- `admin_students_screen.dart` — student account CRUD and search.
- `admin_documents_screen.dart` — document type CRUD and search.
- `admin_requests_screen.dart` — request creation, status updates, deletion,
  search, and status filters.

Student accounts can be created by student self-registration or by an admin
from the Students screen. Admins can add the standard document catalog,
add/edit/remove document types, and create, review, update, and remove student
requests. Student request status and notifications reflect Firestore data in
real time.

Students can search and filter their requests and load older results as needed.
When submitting a request, they can provide a preferred pickup date and time;
this is a preference, not a confirmed appointment. Admins can see it on the
request, and students receive an in-app pickup reminder when the request is
marked ready for claim. Request lists load in pages, and the admin overview
includes live counts for processing and ready-for-claim requests.

## Admin account operations

Admins can create Firebase Auth student accounts, update student profile
details, and deactivate or reactivate student profiles. Deactivation is a
soft-delete: it preserves request history and blocks access through Firestore
rules. Permanently deleting a Firebase Auth user requires a trusted server
environment (for example, a callable Cloud Function); client apps must not
contain Firebase Admin credentials.
