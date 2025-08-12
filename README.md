# Next.js Modern Template

A production-ready Next.js template with modern stack and best practices.

## 🚀 Features

- ⚡ **Next.js 15** with App Router and Turbopack
- 🔐 **NextAuth.js v5** - Complete authentication system
- 🎨 **Tailwind CSS 4** - Modern styling with CSS variables
- 🧱 **Shadcn/ui** - Beautiful UI components
- 🗄️ **Prisma** - Type-safe database ORM
- 📦 **Semantic Release** - Automated versioning and releases
- 🔧 **TypeScript** - Full type safety
- 🎯 **ESLint** - Code linting
- 🚀 **GitHub Actions** - CI/CD pipeline

## 📁 Project Structure

```
src/
├── app/                 # Next.js App Router
│   ├── api/auth/        # NextAuth.js API routes
│   ├── auth/signin/     # Authentication pages
│   └── dashboard/       # Protected pages
├── components/
│   ├── ui/             # Shadcn/ui components
│   ├── auth/           # Authentication components
│   ├── theme/          # Theme components
│   └── providers/      # React providers
├── lib/
│   ├── auth.ts         # NextAuth.js configuration
│   ├── db.ts          # Prisma client
│   └── env.ts         # Environment validation
├── hooks/              # Custom React hooks
├── types/              # TypeScript types
└── constants/          # App constants
```

## 🛠️ Setup

1. **Clone and install dependencies**
```bash
git clone <your-repo>
cd nextjs-template
npm install
```

2. **Configure environment variables**
```bash
cp .env.example .env.local
```

Fill in your database URL and OAuth credentials:
```env
DATABASE_URL="postgresql://..."
NEXTAUTH_SECRET="your-secret"
GITHUB_CLIENT_ID="your-github-id"
GITHUB_CLIENT_SECRET="your-github-secret"
```

3. **Setup database**
```bash
npx prisma generate
npx prisma db push
```

4. **Run development server**
```bash
npm run dev
```

## 🔐 Authentication

- Pre-configured NextAuth.js with GitHub and Google providers
- Database sessions with Prisma
- Protected routes with middleware
- User menu and sign-in components

## 🎨 Theming

- Light/Dark mode with system preference
- CSS custom properties for easy customization
- Responsive design system
- Modern animations and transitions

## 🚀 Deployment

The template includes GitHub Actions for:
- Automated testing and linting
- Semantic versioning
- Automated releases

## 📦 Available Scripts

- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run start` - Start production server
- `npm run lint` - Run ESLint

## 🤝 Contributing

1. Make your changes
2. Follow conventional commits: `feat:`, `fix:`, `chore:`
3. Push to trigger automated release

## 📄 License

MIT
