import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of an exhibition
enum ExhibitionStatus { current, future, past }

/// Exhibition event model — maps directly from Firestore `exhibitions` collection
class ExhibitionModel {
  final String id;
  final String title;
  final String location;
  final String address;
  final DateTime startDate;
  final DateTime endDate;
  final String openTime;
  final String closeTime;
  final String displayTime;
  final String imageUrl;
  final bool isActive;
  final String thankYouMessage;
  final String lastDayMessage;
  final String upcomingMessage;

  const ExhibitionModel({
    required this.id,
    required this.title,
    required this.location,
    required this.address,
    required this.startDate,
    required this.endDate,
    required this.openTime,
    required this.closeTime,
    required this.displayTime,
    required this.imageUrl,
    required this.isActive,
    required this.thankYouMessage,
    required this.lastDayMessage,
    required this.upcomingMessage,
  });

  /// Create from Firestore document snapshot
  factory ExhibitionModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ExhibitionModel(
      id: doc.id,
      title: map['title']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      startDate: parseDate(map['startDate']),
      endDate: parseDate(map['endDate']),
      openTime: map['openTime']?.toString() ?? '',
      closeTime: map['closeTime']?.toString() ?? '',
      displayTime: map['displayTime']?.toString() ?? '',
      imageUrl: map['imageUrl']?.toString() ?? '',
      isActive: map['isActive'] == true,
      thankYouMessage: map['thankYouMessage']?.toString() ?? '',
      lastDayMessage: map['lastDayMessage']?.toString() ?? '',
      upcomingMessage:
          (map['upcomingMessage'] ?? map['upcommingMessage'])?.toString() ?? '',
    );
  }

  /// Convert to map for Firestore write operations
  Map<String, dynamic> toMap() => {
    'title': title,
    'location': location,
    'address': address,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'openTime': openTime,
    'closeTime': closeTime,
    'displayTime': displayTime,
    'imageUrl': imageUrl,
    'isActive': isActive,
    'thankYouMessage': thankYouMessage,
    'lastDayMessage': lastDayMessage,
    'upcomingMessage': upcomingMessage,
  };

  // ─────────────────────────────────────────────────────────────────
  // HELPER GETTERS
  // ─────────────────────────────────────────────────────────────────

  /// Check if exhibition is currently active (within date range AND isActive flag)
  bool get isCurrent {
    if (!isActive) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exhStart = DateTime(startDate.year, startDate.month, startDate.day);
    final exhEnd = DateTime(endDate.year, endDate.month, endDate.day);
    return !today.isBefore(exhStart) && !today.isAfter(exhEnd);
  }

  /// Check if exhibition is in the future (startDate is after today)
  bool get isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exhStart = DateTime(startDate.year, startDate.month, startDate.day);
    return today.isBefore(exhStart);
  }

  /// Check if exhibition is in the past (endDate is before today)
  bool get isPast {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exhEnd = DateTime(endDate.year, endDate.month, endDate.day);
    return today.isAfter(exhEnd);
  }

  /// Get the status of this exhibition
  ExhibitionStatus get status {
    if (isCurrent) return ExhibitionStatus.current;
    if (isFuture) return ExhibitionStatus.future;
    return ExhibitionStatus.past;
  }

  /// Check if today is the last day of the exhibition
  bool get isLastDay {
    if (!isCurrent) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exhEnd = DateTime(endDate.year, endDate.month, endDate.day);
    return today.isAtSameMomentAs(exhEnd);
  }

  /// Get contextual message based on status
  String get contextualMessage {
    if (isFuture) return upcomingMessage;
    if (isPast) return thankYouMessage;
    if (isLastDay) return lastDayMessage;
    return '';
  }

  /// Get sort priority (lower number = higher priority)
  /// Within same priority, sort by:
  /// - Current: most recent start date first
  /// - Future: soonest start date first
  /// - Past: most recent end date first
  int get _sortPriority {
    if (isCurrent) return 0;
    if (isFuture) return 1;
    return 2;
  }

  /// Comparison for sorting — respects priority and date order
  int compareTo(ExhibitionModel other) {
    // First compare priority
    if (_sortPriority != other._sortPriority) {
      return _sortPriority.compareTo(other._sortPriority);
    }

    // Same priority — sort by date
    if (isCurrent) {
      // Current: most recent start date first (descending)
      return other.startDate.compareTo(startDate);
    } else if (isFuture) {
      // Future: soonest start date first (ascending)
      return startDate.compareTo(other.startDate);
    } else {
      // Past: most recent end date first (descending)
      return other.endDate.compareTo(endDate);
    }
  }

  @override
  String toString() =>
      'ExhibitionModel(id: $id, title: $title, status: $status)';
}
