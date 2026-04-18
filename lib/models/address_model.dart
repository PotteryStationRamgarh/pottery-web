import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String street;
  final String addressLine1;
  final String addressLine2;
  final String addressLine3;
  final String landmark;
  final String city;
  final String state;
  final String pincode;
  final String addressType;
  final bool isDefault;
  final bool phoneVerified;
  final DateTime? createdAt;

  AddressModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.street,
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.addressLine3 = '',
    this.landmark = '',
    required this.city,
    required this.state,
    required this.pincode,
    this.addressType = 'Home',
    required this.isDefault,
    this.phoneVerified = false,
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
      addressLine3: map['addressLine3'] as String? ?? '',
      landmark: map['landmark'] as String? ?? '',
      city: map['city'] as String? ?? '',
      state: map['state'] as String? ?? '',
      pincode: map['pincode'] as String? ?? '',
      addressType: map['addressType'] as String? ?? 'Home',
      isDefault: map['isDefault'] as bool? ?? false,
      phoneVerified: map['phoneVerified'] as bool? ?? false,
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
      'addressLine3': addressLine3,
      'landmark': landmark,
      'city': city,
      'state': state,
      'pincode': pincode,
      'addressType': addressType,
      'isDefault': isDefault,
      'phoneVerified': phoneVerified,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
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
    String? addressLine3,
    String? landmark,
    String? city,
    String? state,
    String? pincode,
    String? addressType,
    bool? isDefault,
    bool? phoneVerified,
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
      addressLine3: addressLine3 ?? this.addressLine3,
      landmark: landmark ?? this.landmark,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      addressType: addressType ?? this.addressType,
      isDefault: isDefault ?? this.isDefault,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get normalizedAddressLine1 =>
      addressLine1.isNotEmpty ? addressLine1 : street;

  String get composedStreet {
    return [
      normalizedAddressLine1,
      addressLine2,
      addressLine3,
      landmark.isNotEmpty ? 'Near $landmark' : '',
    ].where((part) => part.trim().isNotEmpty).join(', ');
  }
}
