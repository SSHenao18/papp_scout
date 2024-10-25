import 'package:flutter/material.dart';

class Scout {
  final String name;
  final double latitude;
  final double longitude;
  final String image;

  Scout({
    this.name = 'Unknown',
    required this.latitude,
    required this.longitude,
    required this.image,
  });

  factory Scout.fromJson(Map<String, dynamic> json) {
    return Scout(
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'image': image,
    };
  }
}
