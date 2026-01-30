import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TimeEntry {
  final String id;
  final DateTime date;
  final TimeOfDay? morningTimeIn;
  final TimeOfDay? morningTimeOut;
  final TimeOfDay? afternoonTimeIn;
  final TimeOfDay? afternoonTimeOut;
  final TimeOfDay? eveningTimeIn;
  final TimeOfDay? eveningTimeOut;
  final String? morningTask;
  final String? morningDescription;
  final String? afternoonTask;
  final String? afternoonDescription;
  final String? eveningTask;
  final String? eveningDescription;
  final Map<String, dynamic>? additionalData;

  TimeEntry({
    required this.id,
    required this.date,
    this.morningTimeIn,
    this.morningTimeOut,
    this.afternoonTimeIn,
    this.afternoonTimeOut,
    this.eveningTimeIn,
    this.eveningTimeOut,
    this.morningTask,
    this.morningDescription,
    this.afternoonTask,
    this.afternoonDescription,
    this.eveningTask,
    this.eveningDescription,
    this.additionalData,
  });

  int get totalMinutes {
    int minutes = 0;
    
    if (morningTimeIn != null && morningTimeOut != null) {
      minutes += (morningTimeOut!.hour * 60 + morningTimeOut!.minute) - 
                (morningTimeIn!.hour * 60 + morningTimeIn!.minute);
    }
    
    if (afternoonTimeIn != null && afternoonTimeOut != null) {
      minutes += (afternoonTimeOut!.hour * 60 + afternoonTimeOut!.minute) - 
                (afternoonTimeIn!.hour * 60 + afternoonTimeIn!.minute);
    }
    
    if (eveningTimeIn != null && eveningTimeOut != null) {
      minutes += (eveningTimeOut!.hour * 60 + eveningTimeOut!.minute) - 
                (eveningTimeIn!.hour * 60 + eveningTimeIn!.minute);
    }
    
    return minutes;
  }

  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'morningTimeIn': morningTimeIn != null
          ? {'hour': morningTimeIn!.hour, 'minute': morningTimeIn!.minute}
          : null,
      'morningTimeOut': morningTimeOut != null
          ? {'hour': morningTimeOut!.hour, 'minute': morningTimeOut!.minute}
          : null,
      'afternoonTimeIn': afternoonTimeIn != null
          ? {'hour': afternoonTimeIn!.hour, 'minute': afternoonTimeIn!.minute}
          : null,
      'afternoonTimeOut': afternoonTimeOut != null
          ? {'hour': afternoonTimeOut!.hour, 'minute': afternoonTimeOut!.minute}
          : null,
      'eveningTimeIn': eveningTimeIn != null
          ? {'hour': eveningTimeIn!.hour, 'minute': eveningTimeIn!.minute}
          : null,
      'eveningTimeOut': eveningTimeOut != null
          ? {'hour': eveningTimeOut!.hour, 'minute': eveningTimeOut!.minute}
          : null,
      'morningTask': morningTask,
      'morningDescription': morningDescription,
      'afternoonTask': afternoonTask,
      'afternoonDescription': afternoonDescription,
      'eveningTask': eveningTask,
      'eveningDescription': eveningDescription,
      'additionalData': additionalData,
    };
  }

  factory TimeEntry.fromJson(Map<String, dynamic> json, String docId) {
    return TimeEntry(
      id: docId,
      date: (json['date'] as Timestamp).toDate(),
      morningTimeIn: json['morningTimeIn'] != null
          ? TimeOfDay(
              hour: json['morningTimeIn']['hour'],
              minute: json['morningTimeIn']['minute'],
            )
          : null,
      morningTimeOut: json['morningTimeOut'] != null
          ? TimeOfDay(
              hour: json['morningTimeOut']['hour'],
              minute: json['morningTimeOut']['minute'],
            )
          : null,
      afternoonTimeIn: json['afternoonTimeIn'] != null
          ? TimeOfDay(
              hour: json['afternoonTimeIn']['hour'],
              minute: json['afternoonTimeIn']['minute'],
            )
          : null,
      afternoonTimeOut: json['afternoonTimeOut'] != null
          ? TimeOfDay(
              hour: json['afternoonTimeOut']['hour'],
              minute: json['afternoonTimeOut']['minute'],
            )
          : null,
      eveningTimeIn: json['eveningTimeIn'] != null
          ? TimeOfDay(
              hour: json['eveningTimeIn']['hour'],
              minute: json['eveningTimeIn']['minute'],
            )
          : null,
      eveningTimeOut: json['eveningTimeOut'] != null
          ? TimeOfDay(
              hour: json['eveningTimeOut']['hour'],
              minute: json['eveningTimeOut']['minute'],
            )
          : null,
      morningTask: json['morningTask'],
      morningDescription: json['morningDescription'],
      afternoonTask: json['afternoonTask'],
      afternoonDescription: json['afternoonDescription'],
      eveningTask: json['eveningTask'],
      eveningDescription: json['eveningDescription'],
      additionalData: json['additionalData'],
    );
  }
}

  