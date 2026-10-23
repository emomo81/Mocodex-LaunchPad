import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Allow the hosted sandbox preview host (https://{port}-{sandboxId}.e2b.app)
  // to load dev assets from `next dev`. Wildcards are only valid below the
  // registered-domain level, so '*.e2b.app' is the narrowest working value.
  allowedDevOrigins: ['*.e2b.app'],
};

export default nextConfig;
