# Equb Platform

Equb is a Flutter application and Node.js backend for managing Ethiopian savings groups, contributions, rotating payouts, wallets, notifications, and financial reports.

## Live Deployments

- Frontend: https://equb-platform-psi.vercel.app/
- Backend API: https://equb-backend-t6h8.onrender.com

## Main Features

- Phone registration, OTP verification, login, password reset, and password change
- Equb group creation, joining, member management, and cycle tracking
- Wallet-based contributions and transaction history
- Rotating payout schedules and payout history
- Group activity and in-app notifications
- Financial dashboards and PDF/Excel report exports

## Team

- Edlawit Huluwork
- Etsubdink Gashaw

## Technology

- Frontend: Flutter
- Backend: Node.js, Express.js
- Database: PostgreSQL
- Authentication: JWT and bcrypt

## Local Development

### Backend

```bash
cd Backend
npm install
npm run migrate
npm run dev
```

The local backend runs on `http://localhost:5000` by default. Configure database credentials and other settings in `Backend/.env`.

### Frontend

```bash
cd Frontend
flutter pub get
flutter run
```

## Project Status

The core Version 1 Equb workflow is implemented. Loans, educational content, full Amharic localization, complete admin management, production payment gateways, physical SMS, native push notifications, and some security/session features remain planned for Version 2.
