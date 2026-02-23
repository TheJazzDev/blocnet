This is a [Next.js](https://nextjs.org) project bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
# or
pnpm dev
# or
bun dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

You can start editing the page by modifying `app/page.tsx`. The page auto-updates as you edit the file.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## App Download Section (Dev/Prod Environments)

Landing page has a dedicated download section at `#download`.

Set these env vars in your deployment platform:

```bash
NEXT_PUBLIC_APP_RELEASE_CHANNEL=prod
NEXT_PUBLIC_ANDROID_VERSION=1.0.0
```

How it works:
- Upload APK files into:
  - `public/apks/dev/latest.apk`
  - `public/apks/prod/latest.apk`
- Download button calls API endpoint:
  - `GET /api/download/apk`
- API resolves channel from `NEXT_PUBLIC_APP_RELEASE_CHANNEL` (or `APP_RELEASE_CHANNEL`):
  - `dev` / `development` -> `public/apks/dev/latest.apk`
  - `prod` / `production` / `main` -> `public/apks/prod/latest.apk`

Recommended flow:
- Keep filename fixed as `latest.apk` in each channel folder.
- Replace only that file on each release.
- No landing-page code change needed after every APK build.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
