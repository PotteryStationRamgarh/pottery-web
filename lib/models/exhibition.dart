import 'package:cloud_firestore/cloud_firestore.dart';

class Exhibition {
  final String id;
  final String title;
  final String location;
  final String address;
  final DateTime? startDate;
  final DateTime? endDate;
  final String openTime;
  final String closeTime;
  final String displayTime;
  final String imageUrl;
  final bool isActive;
  final String thankYouMessage;
  final String lastDayMessage;
  final String upcomingMessage;

  const Exhibition({
    required this.id,
    required this.title,
    required this.location,
    required this.address,
    this.startDate,
    this.endDate,
    required this.openTime,
    required this.closeTime,
    required this.displayTime,
    required this.imageUrl,
    required this.isActive,
    required this.thankYouMessage,
    required this.lastDayMessage,
    required this.upcomingMessage,
  });

  factory Exhibition.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return Exhibition(
      id:              doc.id,
      title:           map['title']           as String? ?? '',
      location:        map['location']        as String? ?? '',
      address:         map['address']         as String? ?? '',
      startDate:       (map['startDate']  as Timestamp?)?.toDate(),
      endDate:         (map['endDate']    as Timestamp?)?.toDate(),
      openTime:        map['openTime']        as String? ?? '',
      closeTime:       map['closeTime']       as String? ?? '',
      displayTime:     map['displayTime']     as String? ?? '',
      imageUrl:        map['imageUrl']        as String? ?? '',
      isActive:        map['isActive']        as bool?   ?? false,
      thankYouMessage: map['thankYouMessage'] as String? ?? '',
      lastDayMessage:  map['lastDayMessage']  as String? ?? '',
      // handles both correct spelling and the Firestore typo 'upcommingMessage'
      upcomingMessage: (map['upcomingMessage'] ?? map['upcommingMessage']) as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'title':           title,
    'location':        location,
    'address':         address,
    'startDate':       startDate != null ? Timestamp.fromDate(startDate!) : null,
    'endDate':         endDate   != null ? Timestamp.fromDate(endDate!)   : null,
    'openTime':        openTime,
    'closeTime':       closeTime,
    'displayTime':     displayTime,
    'imageUrl':        imageUrl,
    'isActive':        isActive,
    'thankYouMessage': thankYouMessage,
    'lastDayMessage':  lastDayMessage,
    'upcomingMessage': upcomingMessage,
  };

  Exhibition copyWith({
    String?   id,
    String?   title,
    String?   location,
    String?   address,
    DateTime? startDate,
    DateTime? endDate,
    String?   openTime,
    String?   closeTime,
    String?   displayTime,
    String?   imageUrl,
    bool?     isActive,
    String?   thankYouMessage,
    String?   lastDayMessage,
    String?   upcomingMessage,
  }) => Exhibition(
    id:              id              ?? this.id,
    title:           title           ?? this.title,
    location:        location        ?? this.location,
    address:         address         ?? this.address,
    startDate:       startDate       ?? this.startDate,
    endDate:         endDate         ?? this.endDate,
    openTime:        openTime        ?? this.openTime,
    closeTime:       closeTime       ?? this.closeTime,
    displayTime:     displayTime     ?? this.displayTime,
    imageUrl:        imageUrl        ?? this.imageUrl,
    isActive:        isActive        ?? this.isActive,
    thankYouMessage: thankYouMessage ?? this.thankYouMessage,
    lastDayMessage:  lastDayMessage  ?? this.lastDayMessage,
    upcomingMessage: upcomingMessage ?? this.upcomingMessage,
  );

  /// Returns the right contextual message based on today vs exhibition dates.
  /// Before start → upcomingMessage
  /// On end date  → lastDayMessage
  /// After end    → thankYouMessage
  /// During       → '' (show normal info)
  String get contextualMessage {
    final now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return upcomingMessage;
    if (endDate != null) {
      final lastDay = DateTime(endDate!.year, endDate!.month, endDate!.day);
      final today   = DateTime(now.year, now.month, now.day);
      if (today.isAtSameMomentAs(lastDay)) return lastDayMessage;
      if (now.isAfter(endDate!))           return thankYouMessage;
    }
    return '';
  }

  static Exhibition empty() => const Exhibition(
    id: '', title: '', location: '', address: '',
    openTime: '', closeTime: '', displayTime: '', imageUrl: '',
    isActive: false, thankYouMessage: '', lastDayMessage: '', upcomingMessage: '',
  );
}