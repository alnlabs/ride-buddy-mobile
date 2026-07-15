# Ride Buddy Mobile

Flutter app (`com.alnlabs.ridebuddy`) — Phase 0–4 base carpool client.

**Maps:** OpenStreetMap tiles via [`flutter_map`](https://pub.dev/packages/flutter_map) (Leaflet-style).  
**Geocoding / place search:** [Nominatim](https://nominatim.openstreetmap.org/) (no Google Maps API key).

## Quick start

```bash
# Backend must be running on :8080 (see ../ride-buddy-backend)

cp .env.example .env
# Android emulator: API_BASE_URL=http://10.0.2.2:8080/api/v1
# iOS simulator:    API_BASE_URL=http://127.0.0.1:8080/api/v1
# Physical device:  API_BASE_URL=http://<your-lan-ip>:8080/api/v1

flutter pub get
flutter run
```

Mock OTP: **123456**

## Smoke test

1. Sign in with phone → OTP `123456` → set display name  
2. Profile → Home & Office (Nominatim search)  
3. Profile → My Vehicles → add vehicle (4+ seats for comfort)  
4. Ride → Offer a ride → publish  
5. Second account → Find a ride → book (cash) with pickup/drop on OSM map  
6. Owner opens ride detail → accept booking  
7. Share via WhatsApp / system share sheet  

## Release (Android)

Release keystore: `android/app/upload-keystore.jks` (gitignored)  
Config: `android/key.properties` (gitignored — copy from `key.properties.example`)

```bash
flutter build appbundle --release
# output: build/app/outputs/bundle/release/app-release.aab
```

## Navigation

Home · Ride · Jobs (soon) · Meetups (soon) · Profile

## Branding

- Logo: `assets/logos/app_icon.png` (transparent)  
- Wordmark: **Ride** blue `#2563EB` + **Buddy** orange `#F97316`
