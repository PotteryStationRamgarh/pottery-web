import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String street;
  final String addressLine1;
  final String addressLine2;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final String addressType;
  final bool isDefault;
  final DateTime? createdAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.street,
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.landmark = '',
    required this.city,
    required this.state,
    required this.pincode,
    this.addressType = 'Home',
    required this.isDefault,
    this.createdAt,
  });

  factory AddressModel.fromDoc(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};

    return AddressModel(
      id: doc.id,
      userId: map['userId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      street: map['street'] as String? ?? '',
      addressLine1: map['addressLine1'] as String? ?? '',
      addressLine2: map['addressLine2'] as String? ?? '',
      landmark: map['landmark'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      pincode: map['pincode'] as String? ?? '',
      addressType: map['addressType'] as String? ?? 'Home',
      isDefault: map['isDefault'] as bool? ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'street': composedStreet,
      'addressLine1': normalizedAddressLine1,
      'addressLine2': addressLine2,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pincode': pincode,
      'addressType': addressType,
      'isDefault': isDefault,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  AddressModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? street,
    String? addressLine1,
    String? addressLine2,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
    String? addressType,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      street: street ?? this.street,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      addressType: addressType ?? this.addressType,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get normalizedAddressLine1 =>
      addressLine1.isNotEmpty ? addressLine1 : street;

  String get composedStreet {
    return [
      normalizedAddressLine1,
      addressLine2,
      landmark.isNotEmpty ? 'Near $landmark' : '',
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }
}
