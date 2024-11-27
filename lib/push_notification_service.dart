import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class PushNotificationService {
  static Future<void> sendNotification({
    required String deviceToken,
    required String title,
    required String body,
  }) async {
    try {
      // Load your service account credentials from a JSON file
      final serviceAccountJson = {
        "type": "service_account",
        "project_id": "boosttrainingcourt-60158",
        "private_key_id": "eb619824c4b8765e47bd2832668be857e2e9f5dd",
        "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC1ia4mpiABfZ5f\ngM/brIZXq7YY3UPszsU7cgypcDPZMYnZNF69px5eggZpQCHqk7owp7HOGFt6q/ug\nX16qLYLk716pMxiIC0daWro9s2/sLkbPopn87umDObzZwVHKUywed4aJIlJLqvmG\nE1PNDv00PSqLC1hbeSxQO3i1Ppv+aVklrVulEVhuTRFsCihg2P8wXvNRAMxbEnlW\nyAY26Iz43vxCSuoqDFUoKY4ZP5LotlfADPv5Cbwr30uSeF4e08FK+2bLxxtR8SrV\nwbzMVAgyEbOpnISGXuI31WOLE8ifFZ6j05WxBsR7y48HWR3UN2eS+KetrzVzxEYo\nSrhFdyHRAgMBAAECggEAB8nT0BZMnVnCBp2GdWmRBDACjo2oI0/R7gloJgkRfWQK\n4qfkuGjkBHiaPS/eYKO0v0+DgSjB/HjmUVCkJWORWAB1yIcv2k7XEWce8kSZdLnd\nyXzTs9J9b9cFXVeGGnq/4+D7g3TGsHbB8KzRuaSG7BPDeG6MvHRt+HV7udVpQIR6\npMgHoqJSsKkE11ECLX6ZCO+mxse3tJL5XEBAhPKE9hi/QXON0cal5GH68NIPv4wA\nSDzb+Hd9MN3TEfkygOeYLbN6d1ttTOKBjDkrIIKV1rs4B0PXFOjiYfkwQOi/4SiI\nEAvmSsU7m+fCuFxRyTXky5UMvxb71jEL5FCjyC3QAQKBgQDiUikppx6pSCZXDavJ\nz3pt9YgpTbDeHcuUgjVORENN9QserBN+A4+xiP39yPJf9Uf8ZxJ1udvQcWbiP0ne\nR2+HA32js2yW6L1LPnZ7Efpq46hgoZqB52uYrHOOml/uS159753SXmf1KB4m28pp\ncOki55EYcjTxyLYqWZwc0CowAQKBgQDNWBn0dl/1WsrdmL0eB/9j9WRQ6cptJVT3\ngkt7jCTjLpQjrRNcEq/Q3UhW+hhxB8q35kASe6l7aRJSxlEMd8mOnVAewwcwE8tC\nVE1qa/dl9EBFnsMUynDD7qzrpGuxgAkenTZaOF4els8fjy2QthNDOHyolROrtCAF\nQFYQq9Xx0QKBgBl/2FNxGOtJzcgRKkHatpidCXJd5oegI8ffw9HFry+hZFdYW/ne\nvNnr7XIiqexV3n55voK1JiceH9FuAAyjT9WOdyFyndGC95D6wK6tH+HbNKVuj9ID\nGQRiqcJvck+O/l6CGO4S5POiSYNnUC8BIcNlA9wVQhHb42pyHjzA14ABAoGBAIhB\ngJ99ePkWsOxP8JWf2vCaIWGrcJ3yGqpN9AZcHRH+k2AE9YawA6gFXX4RX+yIrhRP\nHY7mLbTtKLJyU8+BIOaYLlTrNrbJO6Ocyu3mDHjDlW5dBbejCSaKFoYaSTez7Nk6\nmplNM+76RR/84tBWcPu23MkEetQBpwm1Aib3zvQxAoGANrfa1ZrDOrknfhwH271n\npM5/5UjjueOO6ocIhaTX1Ihwv3zIPUDwf7zCitFO/FvhA7JaVxow0kVaQCA8b6tT\nSaEZc2ndmS0qrmxjLTumMFFgDZffnV83lmwFS5xsFiSIxLqsNZpN8IdBhGHfcNmo\nEU7MKLxT7bOD+dD1gVvav4g=\n-----END PRIVATE KEY-----\n",
        "client_email": "firebase-adminsdk-a1pdb@boosttrainingcourt-60158.iam.gserviceaccount.com",
        "client_id": "115714270975305756282",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-a1pdb%40boosttrainingcourt-60158.iam.gserviceaccount.com",
      };

      final credentials = ServiceAccountCredentials.fromJson(serviceAccountJson);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];

      // Fetch the client and access token
      final client = await clientViaServiceAccount(credentials, scopes);
      final token = await client.credentials.accessToken;

      // Send the notification
      final payload = {
        "message": {
          "token": deviceToken,
          "notification": {
            "title": title,
            "body": body,
          },
        }
      };

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/v1/projects/boosttrainingcourt-60158/messages:send'),
        headers: {
          "Authorization": "Bearer ${token.data}",
          "Content-Type": "application/json",
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint("Notification sent successfully.");
      } else {
        debugPrint("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error in sendNotification: $e");
    }
  }
}
