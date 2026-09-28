# Ride Buddy Mobile

Expo (React Native) app (`com.alnlabs.ridebuddy`) — Phase 0–4 base carpool client.

**Maps:** OpenStreetMap / CARTO tiles via `react-native-maps`.  
**Geocoding / place search:** [Nominatim](https://nominatim.openstreetmap.org/) + Photon (optional Google Places key).

## Quick start

```bash
# Backend must be running on :8080 (see ../ride-buddy-backend)

cp .env.example .env
# iOS simulator / Expo web: EXPO_PUBLIC_API_BASE_URL=http://127.0.0.1:8080/api/v1
# Android emulator:         EXPO_PUBLIC_API_BASE_URL=http://10.0.2.2:8080/api/v1
# Physical device:          EXPO_PUBLIC_API_BASE_URL=http://<your-lan-ip>:8080/api/v1

npm install
npx expo start
```

Then press `i` (iOS simulator), `a` (Android emulator), or scan the QR code with Expo Go.

Mock OTP: **123456**

## Smoke test

1. Sign in with phone → OTP `123456` → set display name  
2. Profile → Home & Office (Nominatim search)  
3. Profile → My Vehicles → add vehicle (4+ seats for comfort)  
4. Ride → Offer a ride → publish  
5. Second account → Find a ride → book (cash)  
6. Owner opens ride detail → accept booking  
7. Share via WhatsApp / system share sheet  

## Navigation

Home · Ride · Discover (jobs / meetups / podcast soon) · Account

## Branding

- Logo: `assets/logos/app_icon.png` (transparent)  
- Wordmark: **Ride** blue `#2563EB` + **Buddy** orange `#F97316`
