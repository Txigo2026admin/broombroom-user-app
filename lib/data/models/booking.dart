class Booking {
  final String? id;
  final String? bookingId;
  final String customerName;
  final String customerMobile;
  final String? customerEmail;
  final String serviceType;
  final String? wayType;
  final String? airportDirection;
  final String? rentalPackage;
  final String state;
  final String? pincode;
  final String pickupAddress;
  final String dropAddress;
  final String? distance;
  final String? pickupLat;
  final String? pickupLng;
  final String? dropLat;
  final String? dropLng;
  final String pickupDate;
  final String pickupTime;
  final String? returnDate;
  final String? returnTime;
  final String vehicleCategory;
  final int seater;
  final String? acType;
  final bool allocateOurPilot;
  final double fare;
  final double advance;
  final double dueFare;
  final String? status;
  final List<TimelineItem> timeline;
  final String? driverName;
  final String? driverNumber;
  final String? carNo;

  Booking({
    this.id,
    this.bookingId,
    required this.customerName,
    required this.customerMobile,
    this.customerEmail,
    required this.serviceType,
    this.wayType,
    this.airportDirection,
    this.rentalPackage,
    required this.state,
    this.pincode,
    required this.pickupAddress,
    required this.dropAddress,
    this.distance,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    required this.pickupDate,
    required this.pickupTime,
    this.returnDate,
    this.returnTime,
    required this.vehicleCategory,
    required this.seater,
    this.acType,
    this.allocateOurPilot = false,
    required this.fare,
    this.advance = 0,
    this.dueFare = 0,
    this.status,
    this.timeline = const [],
    this.driverName,
    this.driverNumber,
    this.carNo,
  });

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'customerMobile': customerMobile,
      'customerEmail': customerEmail,
      'serviceType': serviceType,
      'wayType': wayType,
      'airportDirection': airportDirection,
      'rentalPackage': rentalPackage,
      'state': state,
      'pincode': pincode,
      'pickupAddress': pickupAddress,
      'dropAddress': dropAddress,
      'distance': distance,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropLat': dropLat,
      'dropLng': dropLng,
      'pickupDate': pickupDate,
      'pickupTime': pickupTime,
      'returnDate': returnDate,
      'returnTime': returnTime,
      'vehicleCategory': vehicleCategory,
      'seater': seater,
      'acType': acType,
      'allocateOurPilot': allocateOurPilot,
      'fare': fare,
      'advance': advance,
      'dueFare': dueFare,
      'driverName': driverName,
      'driverNumber': driverNumber,
      'carNo': carNo,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'],
      bookingId: json['bookingId'],
      customerName: json['customerName'] ?? '',
      customerMobile: json['customerMobile'] ?? '',
      customerEmail: json['customerEmail'],
      serviceType: json['serviceType'] ?? '',
      wayType: json['wayType'],
      airportDirection: json['airportDirection'],
      rentalPackage: json['rentalPackage'],
      state: json['state'] ?? '',
      pincode: json['pincode'],
      pickupAddress: json['pickupAddress'] ?? '',
      dropAddress: json['dropAddress'] ?? '',
      distance: json['distance'],
      pickupLat: json['pickupLat'],
      pickupLng: json['pickupLng'],
      dropLat: json['dropLat'],
      dropLng: json['dropLng'],
      pickupDate: json['pickupDate'] ?? '',
      pickupTime: json['pickupTime'] ?? '',
      returnDate: json['returnDate'],
      returnTime: json['returnTime'],
      vehicleCategory: json['vehicleCategory'] ?? '',
      seater: json['seater'] ?? 0,
      acType: json['acType'],
      allocateOurPilot: json['allocateOurPilot'] ?? false,
      fare: (json['fare'] ?? 0).toDouble(),
      advance: (json['advance'] ?? 0).toDouble(),
      dueFare: (json['dueFare'] ?? 0).toDouble(),
      status: json['status'],
      timeline: (json['timeline'] as List? ?? [])
          .map((item) => TimelineItem.fromJson(item))
          .toList(),
      driverName: json['driverName'],
      driverNumber: json['driverNumber'],
      carNo: json['carNo'],
    );
  }
}

class TimelineItem {
  final String status;
  final String message;
  final DateTime timestamp;

  TimelineItem({
    required this.status,
    required this.message,
    required this.timestamp,
  });

  factory TimelineItem.fromJson(Map<String, dynamic> json) {
    return TimelineItem(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }
}
