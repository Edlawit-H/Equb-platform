# Equb Mobile App Platform

A mobile application platform for managing traditional Ethiopian savings groups (Equb) with digital features.

## 🚀 Quick Start

### Prerequisites

- Node.js (v18 or higher)
- PostgreSQL (v14 or higher)
- npm or yarn
- Firebase account (for push notifications)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Equb-platform
   ```

2. **Install backend dependencies**
   ```bash
   cd Backend
   npm install
   ```

3. **Configure environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and update the following:
   - Database credentials (`DB_HOST`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`)
   - JWT secret (minimum 32 characters)
   - Firebase credentials for push notifications
   - Other configuration as needed

4. **Setup PostgreSQL database**
   ```bash
   # Create database
   createdb equb_db
   
   # Run migrations
   npm run migrate
   ```

5. **Start development server**
   ```bash
   npm run dev
   ```

The server will start on `http://localhost:5000` (or the PORT specified in your .env file).

## 🛠️ Available Scripts

### Backend

```bash
# Development with hot reload
npm run dev

# Build TypeScript
npm run build

# Start production server
npm start

# Run tests
npm test

# Run database migrations
npm run migrate

# Lint code
npm run lint
```

## 🗄️ Database Schema

The application uses PostgreSQL with the following main tables:

- **users** - User accounts with phone authentication
- **equb_groups** - Equb group information
- **group_members** - Group membership records
- **contributions** - Member contributions
- **payouts** - Payout records
- **transactions** - Financial transactions
- **notifications** - Push notifications
- **audit_logs** - System audit trail

See `Backend/src/db/migrations/` for detailed schema.

## 🔐 Authentication

The platform uses JWT-based authentication:
- Access tokens (short-lived, 15 minutes)
- Refresh tokens (long-lived, 30 days)
- Phone number + OTP verification

## 📱 Features

### User Features
- Phone-based registration and login
- OTP verification
- Profile management
- Multi-group membership

### Group Features
- Create and manage Equb groups
- Invite members
- Automated rotation scheduling
- Contribution tracking
- Payout management

### Financial Features
- Secure payment processing
- Transaction history
- Contribution reminders
- Payout notifications

### Admin Features
- User management
- Group monitoring
- Financial reports (PDF/Excel export)
- Audit logs
- System analytics

### Notifications
- Push notifications via Firebase
- Contribution reminders
- Payout alerts
- Group updates

## 🔧 Configuration

### Environment Variables

See `.env.example` for all available configuration options:

- **Server**: Port, environment mode
- **Database**: PostgreSQL connection details
- **JWT**: Secret keys and token expiration
- **OTP**: Expiry times and attempt limits
- **Firebase**: FCM credentials for push notifications
- **File Upload**: Directory and size limits
- **CORS**: Allowed origins

### Development Workflow

1. Pull latest changes: `git pull origin main`
2. Create feature branch: `git checkout -b feature/your-feature-name`
3. Make changes and commit: `git commit -m "Description"`
4. Push to remote: `git push origin feature/your-feature-name`
5. Create Pull Request for review

### Code Standards

- Use TypeScript for type safety
- Follow existing code structure and naming conventions
- Write meaningful commit messages
- Test your changes before pushing
- Keep functions small and focused
- Add comments for complex logic

## 🧪 Testing

```bash
# Run all tests
npm test

# Run tests with coverage
npm test -- --coverage
```

## 📝 API Documentation

API documentation will be available at `/api-docs` when the server is running (coming soon).

## 🚀 Deployment

### Production Build

```bash
cd Backend
npm run build
npm start
```

### Environment Setup

Ensure production environment variables are properly set in your hosting platform.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
