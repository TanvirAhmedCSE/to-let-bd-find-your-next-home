import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/notification_model.dart';
import '../models/chat_model.dart';
import '../models/user_location_model.dart';
import '../utils/constants.dart';
import 'notification_service.dart';
import 'location_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // AREAS  (division_district_thana_area  ->  used as document id)
  Future<void> ensureAreaExists({
    required String searchKey,
    required String area,
    required String division,
    required String district,
    required String thana,
  }) async {
    final ref = _db.collection('areas').doc(searchKey);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'area': area,
        'division': division,
        'district': district,
        'thana': thana,
        'searchKey': searchKey,
        'postCount': 0,
      });
    }
  }

  Future<void> _incrementAreaPostCount(String searchKey, int delta) async {
    final ref = _db.collection('areas').doc(searchKey);
    await ref.set({
      'postCount': FieldValue.increment(delta),
    }, SetOptions(merge: true));
  }

  // Returns area names (String) whose searchKey starts with [prefix].
  Future<List<Map<String, dynamic>>> searchAreas(String prefix) async {
    if (prefix.isEmpty) return [];
    final end = '$prefix\uf8ff';
    final snap = await _db
        .collection('areas')
        .where('searchKey', isGreaterThanOrEqualTo: prefix)
        .where('searchKey', isLessThan: end)
        .limit(20)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // POSTS
  Future<String> createPost(PostModel post) async {
    final ref = await _db.collection('posts').add(post.toMap());
    await _incrementAreaPostCount(post.areaSearchKey, 1);
    return ref.id;
  }

  Future<void> updatePost(String postId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _db.collection('posts').doc(postId).update(data);
  }

  Future<void> deletePost(PostModel post) async {
    final interestedSnap = await _db
        .collection('posts')
        .doc(post.id)
        .collection('interested')
        .get();

    final chatsSnap = await _db
        .collection('chats')
        .where('postId', isEqualTo: post.id)
        .where('participants', arrayContains: post.uploaderUid)
        .get();

    final batch = _db.batch();

    for (final doc in interestedSnap.docs) {
      final seekerUid = doc.id;

      // the "interested" subcollection entry itself
      batch.delete(doc.reference);

      // owner's "X is interested in your post" notification for this seeker
      final interestedNotifRef = _db
          .collection('notifications')
          .doc(post.uploaderUid)
          .collection('items')
          .doc('${post.id}_$seekerUid');
      batch.delete(interestedNotifRef);

      // the seeker's own mirror doc — avoids a permanent orphan in
      // users/{seekerUid}/interestedPosts
      final mirrorRef = _db
          .collection('users')
          .doc(seekerUid)
          .collection('interestedPosts')
          .doc(post.id);
      batch.delete(mirrorRef);

      // seeker's "post rented" notification, if it exists
      final rentedNotifRef = _db
          .collection('notifications')
          .doc(seekerUid)
          .collection('items')
          .doc('${post.id}_rented');
      batch.delete(rentedNotifRef);

      // seeker's "rent available" notification, if it exists
      final availableNotifRef = _db
          .collection('notifications')
          .doc(seekerUid)
          .collection('items')
          .doc('${post.id}_available');
      batch.delete(availableNotifRef);
    }

    // keep every chat + its full message history, but permanently lock
    // messaging and flag the post as deleted — no "Mark as Available"
    // can ever undo this, unlike the rented lock.
    for (final chatDoc in chatsSnap.docs) {
      batch.update(chatDoc.reference, {
        'postDeleted': true,
        'messagingEnabled': false,
      });
    }

    batch.delete(_db.collection('posts').doc(post.id));

    await batch.commit();

    await _incrementAreaPostCount(post.areaSearchKey, -1);
  }

  Future<PostModel> getPost(String postId) async {
    final doc = await _db.collection('posts').doc(postId).get();
    return PostModel.fromDoc(doc);
  }

  Future<List<PostModel>> fetchRecentPosts({int limit = 30}) async {
    final snap = await _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get(const GetOptions(source: Source.server));
    return snap.docs.map((d) => PostModel.fromDoc(d)).toList();
  }

  Stream<List<PostModel>> myPostsStream(String uid) {
    return _db
        .collection('posts')
        .where('uploaderUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostModel.fromDoc(d)).toList());
  }

  Stream<List<PostModel>> recentPostsStream({int limit = 30}) {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => PostModel.fromDoc(d)).toList());
  }

  Future<List<PostModel>> searchPosts({
    String? propertyType,
    String? division,
    String? district,
    String? thana,
    String? area,
    double? minRent,
    double? maxRent,
    DateTime? availableFromStart,
    DateTime? availableFromEnd,
  }) async {
    final snap = await _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .get();
    var results = snap.docs.map((d) => PostModel.fromDoc(d)).toList();
    if (propertyType != null && propertyType.isNotEmpty) {
      results = results.where((p) => p.propertyType == propertyType).toList();
    }
    if (division != null && division.isNotEmpty) {
      results = results.where((p) => p.division == division).toList();
    }
    if (district != null && district.isNotEmpty) {
      results = results.where((p) => p.district == district).toList();
    }
    if (thana != null && thana.isNotEmpty) {
      results = results.where((p) => p.thana == thana).toList();
    }
    if (area != null && area.isNotEmpty && area != 'All') {
      results = results.where((p) => p.area == area).toList();
    }
    if (minRent != null) {
      results = results.where((p) => p.rent >= minRent).toList();
    }
    if (maxRent != null) {
      results = results.where((p) => p.rent <= maxRent).toList();
    }
    if (availableFromStart != null) {
      results = results.where((p) {
        if (p.availableFrom == null) return false;
        final postDate = p.availableFrom!.toDate();
        final afterStart = !postDate.isBefore(availableFromStart);
        final beforeEnd = availableFromEnd == null
            ? true
            : !postDate.isAfter(availableFromEnd);
        return afterStart && beforeEnd;
      }).toList();
    }
    return results;
  }

  // INTERESTED
  Future<bool> isInterested(String postId, String seekerUid) async {
    final doc = await _db
        .collection('posts')
        .doc(postId)
        .collection('interested')
        .doc(seekerUid)
        .get();
    return doc.exists;
  }

  Future<void> addInterest({
    required PostModel post,
    required String seekerUid,
    required String seekerName,
  }) async {
    final postRef = _db.collection('posts').doc(post.id);
    final interestRef = postRef.collection('interested').doc(seekerUid);
    final notifRef = _db
        .collection('notifications')
        .doc(post.uploaderUid)
        .collection('items')
        .doc('${post.id}_$seekerUid');

    final batch = _db.batch();
    batch.set(interestRef, {
      'seekerUid': seekerUid,
      'seekerName': seekerName,
      'uploaderUid': post.uploaderUid,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(postRef, {'interestedCount': FieldValue.increment(1)});

    batch.set(
      notifRef,
      NotificationModel(
        id: '',
        type: kNotifInterested,
        fromUid: seekerUid,
        fromName: seekerName,
        postId: post.id,
        postTitle: post.title,
      ).toMap(),
    );

    final myInterestedRef = _db
        .collection('users')
        .doc(seekerUid)
        .collection('interestedPosts')
        .doc(post.id);
    batch.set(myInterestedRef, {
      'postId': post.id,
      'uploaderUid': post.uploaderUid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await NotificationService.sendInterestedNotification(
      uploaderUid: post.uploaderUid,
      seekerName: seekerName,
      postTitle: post.title,
      postId: post.id,
      notifId: notifRef.id,
    );
  }

  Future<void> removeInterest({
    required PostModel post,
    required String seekerUid,
  }) async {
    final postRef = _db.collection('posts').doc(post.id);
    final interestRef = postRef.collection('interested').doc(seekerUid);
    final notifRef = _db
        .collection('notifications')
        .doc(post.uploaderUid)
        .collection('items')
        .doc('${post.id}_$seekerUid');

    final batch = _db.batch();
    batch.delete(interestRef);
    batch.update(postRef, {'interestedCount': FieldValue.increment(-1)});
    batch.delete(notifRef);

    final myInterestedRef = _db
        .collection('users')
        .doc(seekerUid)
        .collection('interestedPosts')
        .doc(post.id);
    batch.delete(myInterestedRef);

    final availableNotifRef = _db
        .collection('notifications')
        .doc(seekerUid)
        .collection('items')
        .doc('${post.id}_available');
    batch.delete(availableNotifRef);

    final rentedNotifRef = _db
        .collection('notifications')
        .doc(seekerUid)
        .collection('items')
        .doc('${post.id}_rented');
    batch.delete(rentedNotifRef);

    await batch.commit();
  }

  // All posts the given seeker has marked as interested.
  Future<List<PostModel>> interestedPostsFor(String seekerUid) async {
    final snap = await _db
        .collection('users')
        .doc(seekerUid)
        .collection('interestedPosts')
        .orderBy('createdAt', descending: true)
        .get();
    final posts = <PostModel>[];
    for (final doc in snap.docs) {
      final postDoc = await _db.collection('posts').doc(doc.id).get();
      if (postDoc.exists) posts.add(PostModel.fromDoc(postDoc));
    }
    return posts;
  }

  Stream<List<Map<String, dynamic>>> interestedUsersStream(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('interested')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  Future<void> markPostRented(PostModel post) async {
    await _db.collection('posts').doc(post.id).update({
      'status': kStatusRented,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final interestedSnap = await _db
        .collection('posts')
        .doc(post.id)
        .collection('interested')
        .get();

    final chatsSnap = await _db
        .collection('chats')
        .where('postId', isEqualTo: post.id)
        .where('participants', arrayContains: post.uploaderUid)
        .get();

    if (interestedSnap.docs.isEmpty && chatsSnap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in interestedSnap.docs) {
      final seekerUid = doc.id;
      final notifRef = _db
          .collection('notifications')
          .doc(seekerUid)
          .collection('items')
          .doc('${post.id}_rented');
      batch.set(notifRef, {
        'type': kNotifPostRented,
        'fromUid': post.uploaderUid,
        'fromName': post.uploaderName,
        'postId': post.id,
        'postTitle': post.title,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    for (final chatDoc in chatsSnap.docs) {
      batch.update(chatDoc.reference, {
        'messagingEnabled': false,
        'statusEventType': 'rented',
        'statusEventTime': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    await NotificationService.sendPostRentedNotification(
      seekerUids: interestedSnap.docs.map((d) => d.id).toList(),
      postTitle: post.title,
      postId: post.id,
      notifId: '${post.id}_rented',
    );
  }

  Future<void> markPostAvailable(PostModel post) async {
    await _db.collection('posts').doc(post.id).update({
      'status': kStatusActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final interestedSnap = await _db
        .collection('posts')
        .doc(post.id)
        .collection('interested')
        .get();

    final chatsSnap = await _db
        .collection('chats')
        .where('postId', isEqualTo: post.id)
        .where('participants', arrayContains: post.uploaderUid)
        .get();

    if (interestedSnap.docs.isEmpty && chatsSnap.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in interestedSnap.docs) {
      final seekerUid = doc.id;

      final rentedNotifRef = _db
          .collection('notifications')
          .doc(seekerUid)
          .collection('items')
          .doc('${post.id}_rented');
      batch.delete(rentedNotifRef);

      final availableNotifRef = _db
          .collection('notifications')
          .doc(seekerUid)
          .collection('items')
          .doc('${post.id}_available');
      batch.set(availableNotifRef, {
        'type': kNotifRentAvailable,
        'fromUid': post.uploaderUid,
        'fromName': post.uploaderName,
        'postId': post.id,
        'postTitle': post.title,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    }

    for (final chatDoc in chatsSnap.docs) {
      batch.update(chatDoc.reference, {
        'messagingEnabled': true,
        'statusEventType': 'available',
        'statusEventTime': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    await NotificationService.sendRentAvailableNotification(
      seekerUids: interestedSnap.docs.map((d) => d.id).toList(),
      postTitle: post.title,
      postId: post.id,
      notifId: '${post.id}_available',
    );
  }

  // NOTIFICATIONS
  Stream<List<NotificationModel>> notificationsStream(String uid) {
    return _db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) => NotificationModel.fromDoc(d)).toList(),
        );
  }

  Stream<int> unreadNotificationsCountStream(String uid) {
    return notificationsStream(
      uid,
    ).map((notifs) => notifs.where((n) => !n.read).length);
  }

  Future<void> markNotificationRead(String uid, String notifId) async {
    await _db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(notifId)
        .update({'read': true});
  }

  Future<void> markAllNotificationsRead(String uid) async {
    final snap = await _db
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  // CHAT
  String chatIdFor(String postId, String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${postId}_${ids[0]}_${ids[1]}';
  }

  Future<String> getOrCreateChat({
    required String postId,
    required String postTitle,
    required String postImageUrl,
    required String uploaderUid,
    required String uploaderName,
    required String seekerUid,
    required String seekerName,
  }) async {
    final chatId = chatIdFor(postId, uploaderUid, seekerUid);
    final ref = _db.collection('chats').doc(chatId);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'participants': [uploaderUid, seekerUid],
        'participantNames': {uploaderUid: uploaderName, seekerUid: seekerName},
        'postId': postId,
        'postTitle': postTitle,
        'postImageUrl': postImageUrl,
        'uploaderUid': uploaderUid,
        'seekerUid': seekerUid,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unread': {uploaderUid: 0, seekerUid: 0},
        'messagingEnabled': true,
        'statusEventType': null,
      });
    }
    return chatId;
  }

  Stream<ChatModel?> chatStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) => doc.exists ? ChatModel.fromDoc(doc) : null);
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String otherUid,
    required String text,
    String? imageUrl,
  }) async {
    final chatRef = _db.collection('chats').doc(chatId);
    final msgRef = chatRef.collection('messages').doc();
    final batch = _db.batch();
    batch.set(msgRef, {
      'senderId': senderId,
      'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'seen': false,
    });

    batch.update(chatRef, {
      'lastMessage': (imageUrl != null && text.isEmpty) ? '📷 Photo' : text,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unread.$otherUid': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> resetUnread(String chatId, String myUid) async {
    await _db.collection('chats').doc(chatId).update({'unread.$myUid': 0});
  }

  Stream<List<ChatModel>> chatListStream(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatModel.fromDoc(d)).toList());
  }

  Stream<List<MessageModel>> messagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MessageModel.fromDoc(d)).toList());
  }

  Stream<int> totalUnreadCountStream(String uid) {
    return chatListStream(uid).map((chats) {
      int total = 0;
      for (final chat in chats) {
        total += chat.unread[uid] ?? 0;
      }
      return total;
    });
  }

  // USER LOCATION (for "Best for You")
  Future<void> saveUserLocation({
    required String uid,
    required String division,
    required String district,
    required String thana,
    required String area,
  }) async {
    await _db.collection('users').doc(uid).set({
      'division': division,
      'district': district,
      'thana': thana,
      'area': area,
    }, SetOptions(merge: true));
  }

  Future<UserLocationModel?> getUserLocation(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null) return null;
    final division = data['division'] as String?;
    final district = data['district'] as String?;
    final thana = data['thana'] as String?;
    final area = data['area'] as String?;
    if (division == null || district == null || thana == null || area == null) {
      return null;
    }
    return UserLocationModel(
      division: division,
      district: district,
      thana: thana,
      area: area,
    );
  }

  Future<List<PostModel>> fetchBestForYou({
    required UserLocationModel location,
    required String excludeUid,
    int limit = 60,
  }) async {
    try {
      final exactKey = LocationService.buildAreaSearchKey(
        division: location.division,
        district: location.district,
        thana: location.thana,
        area: location.area,
      );
      final prefix = LocationService.buildPrefix(
        division: location.division,
        district: location.district,
        thana: location.thana,
      );
      final prefixEnd = '$prefix\uf8ff';

      final exactSnap = await _db
          .collection('posts')
          .where('areaSearchKey', isEqualTo: exactKey)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      final thanaSnap = await _db
          .collection('posts')
          .where('areaSearchKey', isGreaterThanOrEqualTo: prefix)
          .where('areaSearchKey', isLessThan: prefixEnd)
          .orderBy('areaSearchKey')
          .limit(200)
          .get();

      final exactPosts = exactSnap.docs
          .map((d) => PostModel.fromDoc(d))
          .where((p) => p.uploaderUid != excludeUid)
          .toList();
      final exactIds = exactPosts.map((p) => p.id).toSet();

      final thanaPosts =
          thanaSnap.docs
              .map((d) => PostModel.fromDoc(d))
              .where(
                (p) => !exactIds.contains(p.id) && p.uploaderUid != excludeUid,
              )
              .toList()
            ..sort((a, b) {
              final aTime = a.createdAt?.toDate() ?? DateTime(0);
              final bTime = b.createdAt?.toDate() ?? DateTime(0);
              return bTime.compareTo(aTime);
            });

      return [...exactPosts, ...thanaPosts].take(limit).toList();
    } catch (e) {
      return [];
    }
  }
}
