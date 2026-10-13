class Booking {
  final String? id;
  final String? bookingId;
  final String customerName;
  final String customerMobile;
  final String? customerEmail;
  final String serviceType;
  final String? wayType;
  final String? airportDirection;
  final String? airportTerminal;
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
    this.airportTerminal,
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
      'airportTerminal': airportTerminal,
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
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      return int.tryParse(value.toString()) ?? 0;
    }

    return Booking(
      id: (json['_id'] ?? json['id'])?.toString(),
      bookingId: json['bookingId']?.toString(),
      customerName: json['customerName']?.toString() ?? '',
      customerMobile: json['customerMobile']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString(),
      serviceType: json['serviceType']?.toString() ?? '',
      wayType: json['wayType']?.toString(),
      airportDirection: json['airportDirection']?.toString(),
      airportTerminal: json['airportTerminal']?.toString(),
      rentalPackage: json['rentalPackage']?.toString(),
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString(),
      pickupAddress: json['pickupAddress']?.toString() ?? '',
      dropAddress: json['dropAddress']?.toString() ?? '',
      distance: json['distance']?.toString(),
      pickupLat: json['pickupLat']?.toString(),
      pickupLng: json['pickupLng']?.toString(),
      dropLat: json['dropLat']?.toString(),
      dropLng: json['dropLng']?.toString(),
      pickupDate: json['pickupDate']?.toString() ?? '',
      pickupTime: json['pickupTime']?.toString() ?? '',
      returnDate: json['returnDate']?.toString(),
      returnTime: json['returnTime']?.toString(),
      vehicleCategory: json['vehicleCategory']?.toString() ?? '',
      seater: parseInt(json['seater']),
      acType: json['acType']?.toString(),
      allocateOurPilot: json['allocateOurPilot'] == true,
      fare: parseDouble(json['fare']),
      advance: parseDouble(json['advance']),
      dueFare: parseDouble(json['dueFare']),
      status: json['status']?.toString(),
      timeline: (json['timeline'] as List? ?? [])
          .map((item) => TimelineItem.fromJson(item))
          .toList(),
      driverName: json['driverName']?.toString(),
      driverNumber: json['driverNumber']?.toString(),
      carNo: json['carNo']?.toString(),
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
