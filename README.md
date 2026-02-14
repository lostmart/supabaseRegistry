# Reussir Civique - Supabase Backend

A modern backend service built with [Supabase](https://supabase.com/) for the Reussir Civique project. This repository contains the database schema, migrations, and local development setup for the application's backend infrastructure.

## Features

- **PostgreSQL Database** - Fully managed relational database with version 17
- **Supabase Auth** - Built-in authentication system with email/password and OAuth support
- **Realtime API** - Real-time synchronization using PostgreSQL listen/notify
- **Storage** - File storage with S3-compatible interface (50MiB file size limit)
- **API Endpoints** - Auto-generated REST and GraphQL APIs from database schema
- **Local Development** - Complete local development environment with Supabase CLI

## Prerequisites

- Node.js 18+ and npm/pnpm
- Docker and Docker Compose (for local Supabase stack)
- [Supabase CLI](https://supabase.com/docs/guides/cli)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd supabase-back
```

2. Install dependencies:
```bash
npm install
```

3. Set up environment variables:
```bash
cp supabase/.env.local.example supabase/.env.local
```

4. Start the local Supabase stack:
```bash
npm run supabase:start
```

This will start all services:
- **API Server**: http://127.0.0.1:54321
- **Database**: localhost:54322
- **Studio**: http://127.0.0.1:54323
- **Email Testing**: http://127.0.0.1:54324

## Available Scripts

### Database Management

- `npm run supabase:start` - Start the local Supabase development stack
- `npm run supabase:stop` - Stop the local Supabase stack
- `npm run supabase:status` - Check the status of running services
- `npm run supabase:push` - Push database changes to the database
- `npm run supabase:pull` - Pull schema changes from the database
- `npm run supabase:reset` - Reset database and apply migrations/seeds

## Project Structure

```
supabase-back/
├── supabase/
│   ├── config.toml          # Supabase configuration
│   ├── seed.sql             # Database seed data
│   └── .env.local           # Local environment variables
├── docs/                     # Documentation files
├── package.json             # Node dependencies
└── README.md               # This file
```

## Configuration

### Database Configuration
Edit `supabase/config.toml` to modify:
- PostgreSQL version: Major version 17
- API port: 54321 (REST/GraphQL endpoints)
- Database port: 54322
- Maximum rows per request: 1000
- File storage limit: 50MiB

### Authentication Settings
Located in `supabase/config.toml`:
- Email-based signup: Enabled
- JWT expiry: 1 hour (3600 seconds)
- Refresh token rotation: Enabled
- Site URL: http://127.0.0.1:3000
- Redirect URLs: Configure for your frontend application

### Storage Configuration
- S3-compatible storage enabled
- Default file size limit: 50MiB
- Can be customized per bucket in config

## Local Development Workflow

1. **Start services:**
   ```bash
   npm run supabase:start
   ```

2. **Access Supabase Studio:**
   - Open http://127.0.0.1:54323 in your browser
   - Manage tables, test APIs, and configure auth

3. **Make database changes:**
   - Use Studio UI or run raw SQL
   - Track changes automatically

4. **Migrate changes:**
   ```bash
   npm run supabase:push    # Push to database
   npm run supabase:pull    # Pull from database
   ```

5. **Reset development data:**
   ```bash
   npm run supabase:reset   # Resets DB and applies seeds
   ```

## Dependencies

### Production
- `@supabase/supabase-js` - Supabase JavaScript client
- `@google/gemini-cli` - Google Gemini CLI integration

### Development
- `supabase` - Supabase CLI for local development

## Environment Variables

Create `supabase/.env.local` with:
```
OPENAI_API_KEY=your_openai_key_here
# Add other environment variables as needed
```

## Testing Emails

During local development, emails sent by the auth system are captured by Inbucket:
- Access email inbox: http://127.0.0.1:54324
- View all emails sent in development
- Test email-based authentication flows

## Connecting Your Frontend

Configure your frontend to connect to the local backend:

```javascript
import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'http://127.0.0.1:54321'
const supabaseAnonKey = 'your-anon-key' // Get from Studio

export const supabase = createClient(supabaseUrl, supabaseAnonKey)
```

## Production Deployment

For production deployment, use Supabase Cloud or your own Supabase instance:
1. Set environment variables for production
2. Run migrations against production database
3. Configure auth providers and URLs
4. Update frontend connection strings

## Troubleshooting

### Services won't start
```bash
npm run supabase:stop
npm run supabase:start
```

### Database port conflicts
Change the port in `supabase/config.toml` [db] section

### Reset to clean state
```bash
npm run supabase:reset
```

This will:
- Drop all tables and schemas
- Apply migrations from schema files
- Run seeds from `seed.sql`

## Documentation

- [Supabase Docs](https://supabase.com/docs)
- [Local Development Guide](https://supabase.com/docs/guides/local-development)
- [CLI Reference](https://supabase.com/docs/reference/cli)
- [Database Functions & Triggers](https://supabase.com/docs/guides/database)

## Contributing

1. Create a feature branch
2. Make your changes
3. Test locally with `npm run supabase:start`
4. Push changes and create a pull request

## License

ISC
