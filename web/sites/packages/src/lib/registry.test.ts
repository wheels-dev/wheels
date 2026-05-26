import { afterEach, describe, expect, it, vi } from 'vitest';

describe('registry', () => {
  const fetchSpy = vi.spyOn(globalThis, 'fetch');

  afterEach(() => {
    fetchSpy.mockReset();
    vi.unstubAllEnvs();
    vi.resetModules();
  });

  describe('listPackageNames', () => {
    it('returns directory names from GH contents API, sorted and filtered', async () => {
      fetchSpy.mockResolvedValueOnce(
        new Response(
          JSON.stringify([
            { name: 'wheels-sentry', type: 'dir' },
            { name: 'wheels-hotwire', type: 'dir' },
            { name: 'README.md', type: 'file' },
          ]),
          { status: 200 },
        ),
      );

      const { listPackageNames } = await import('./registry');
      const names = await listPackageNames();

      expect(names).toEqual(['wheels-hotwire', 'wheels-sentry']);
      expect(fetchSpy).toHaveBeenCalledWith(
        'https://api.github.com/repos/wheels-dev/wheels-packages/contents/packages?ref=main',
        expect.anything(),
      );
    });

    it('uses WHEELS_PACKAGES_REGISTRY override when set', async () => {
      vi.stubEnv('WHEELS_PACKAGES_REGISTRY', 'acme/custom-pkgs');
      vi.resetModules();

      fetchSpy.mockResolvedValueOnce(
        new Response(JSON.stringify([{ name: 'foo', type: 'dir' }]), { status: 200 }),
      );

      const { listPackageNames } = await import('./registry');
      await listPackageNames();

      expect(fetchSpy).toHaveBeenCalledWith(
        'https://api.github.com/repos/acme/custom-pkgs/contents/packages?ref=main',
        expect.anything(),
      );

      vi.unstubAllEnvs();
    });

    it('throws a descriptive error on non-200 response', async () => {
      fetchSpy.mockResolvedValueOnce(
        new Response('rate limited', { status: 403, statusText: 'Forbidden' }),
      );

      const { listPackageNames } = await import('./registry');
      await expect(listPackageNames()).rejects.toThrow(/Registry fetch failed: 403/);
    });

    it('sends an Authorization header when GITHUB_TOKEN is set', async () => {
      vi.stubEnv('GITHUB_TOKEN', 'ghs_test-token-abc');
      vi.resetModules();

      fetchSpy.mockResolvedValueOnce(
        new Response(JSON.stringify([{ name: 'foo', type: 'dir' }]), { status: 200 }),
      );

      const { listPackageNames } = await import('./registry');
      await listPackageNames();

      const [, init] = fetchSpy.mock.calls[0];
      const sentHeaders = (init as RequestInit | undefined)?.headers as
        | Record<string, string>
        | undefined;
      expect(sentHeaders?.Authorization).toBe('Bearer ghs_test-token-abc');
    });

    it('omits Authorization when no token env var is set', async () => {
      vi.stubEnv('GITHUB_TOKEN', '');
      vi.stubEnv('GH_TOKEN', '');
      vi.resetModules();

      fetchSpy.mockResolvedValueOnce(
        new Response(JSON.stringify([{ name: 'foo', type: 'dir' }]), { status: 200 }),
      );

      const { listPackageNames } = await import('./registry');
      await listPackageNames();

      const [, init] = fetchSpy.mock.calls[0];
      const sentHeaders = (init as RequestInit | undefined)?.headers as
        | Record<string, string>
        | undefined;
      expect(sentHeaders?.Authorization).toBeUndefined();
    });
  });

  describe('fetchManifest', () => {
    it('returns a parsed manifest from raw.githubusercontent.com', async () => {
      fetchSpy.mockResolvedValueOnce(
        new Response(
          JSON.stringify({
            name: 'wheels-sentry',
            description: 'Sentry for Wheels',
            homepage: 'https://github.com/wheels-dev/wheels-sentry',
            tags: ['monitoring'],
            versions: [
              {
                version: '1.0.0',
                publishedAt: '2026-04-01T00:00:00Z',
                wheelsVersion: '>=4.0',
                sourceTag: 'v1.0.0',
                tarball: 'https://example.com/t.tar.gz',
                sha256: 'abc',
              },
            ],
          }),
          { status: 200 },
        ),
      );

      const { fetchManifest } = await import('./registry');
      const m = await fetchManifest('wheels-sentry');

      expect(m.name).toBe('wheels-sentry');
      expect(m.versions).toHaveLength(1);
      expect(fetchSpy).toHaveBeenCalledWith(
        'https://raw.githubusercontent.com/wheels-dev/wheels-packages/main/packages/wheels-sentry/manifest.json',
        expect.anything(),
      );
    });

    it('throws on non-200', async () => {
      fetchSpy.mockResolvedValueOnce(new Response('not found', { status: 404 }));
      const { fetchManifest } = await import('./registry');
      await expect(fetchManifest('missing')).rejects.toThrow(/Registry fetch failed: 404/);
    });
  });

  describe('fetchReadme', () => {
    it('returns README text from raw.githubusercontent.com', async () => {
      fetchSpy.mockResolvedValueOnce(
        new Response('# wheels-sentry\n\nSentry for Wheels.', { status: 200 }),
      );

      const { fetchReadme } = await import('./registry');
      const text = await fetchReadme('wheels-sentry');

      expect(text).toContain('# wheels-sentry');
      expect(fetchSpy).toHaveBeenCalledWith(
        'https://raw.githubusercontent.com/wheels-dev/wheels-packages/main/packages/wheels-sentry/README.md',
        expect.anything(),
      );
    });

    it('throws on non-200', async () => {
      fetchSpy.mockResolvedValueOnce(new Response('', { status: 404 }));
      const { fetchReadme } = await import('./registry');
      await expect(fetchReadme('missing')).rejects.toThrow(/Registry fetch failed: 404/);
    });
  });

  describe('listAll', () => {
    it('returns enriched summaries for every package, latest version from last entry', async () => {
      fetchSpy
        .mockResolvedValueOnce(
          new Response(
            JSON.stringify([{ name: 'wheels-sentry', type: 'dir' }]),
            { status: 200 },
          ),
        )
        .mockResolvedValueOnce(
          new Response(
            JSON.stringify({
              name: 'wheels-sentry',
              description: 'Sentry for Wheels',
              homepage: 'https://github.com/wheels-dev/wheels-sentry',
              tags: ['monitoring'],
              versions: [
                { version: '1.0.0', publishedAt: '2026-01-01T00:00:00Z', wheelsVersion: '>=4.0', sourceTag: 'v1.0.0', tarball: 'x', sha256: 'y' },
                { version: '1.1.0', publishedAt: '2026-04-01T00:00:00Z', wheelsVersion: '>=4.0', sourceTag: 'v1.1.0', tarball: 'x', sha256: 'y' },
              ],
            }),
            { status: 200 },
          ),
        );

      const { listAll } = await import('./registry');
      const all = await listAll();

      expect(all).toHaveLength(1);
      expect(all[0].name).toBe('wheels-sentry');
      expect(all[0].latestVersion).toBe('1.1.0');
      expect(all[0].publishedAt).toBe('2026-04-01T00:00:00Z');
      expect(all[0].tags).toEqual(['monitoring']);
      expect(all[0].homepage).toBe('https://github.com/wheels-dev/wheels-sentry');
    });

    it('defaults missing optional fields to empty values', async () => {
      fetchSpy
        .mockResolvedValueOnce(
          new Response(JSON.stringify([{ name: 'minimal', type: 'dir' }]), { status: 200 }),
        )
        .mockResolvedValueOnce(
          new Response(
            JSON.stringify({
              name: 'minimal',
              description: '',
              versions: [
                { version: '1.0.0', publishedAt: '2026-04-01T00:00:00Z', wheelsVersion: '>=4.0', sourceTag: 'v1.0.0', tarball: 'x', sha256: 'y' },
              ],
            }),
            { status: 200 },
          ),
        );

      const { listAll } = await import('./registry');
      const all = await listAll();

      expect(all[0].homepage).toBe('');
      expect(all[0].tags).toEqual([]);
    });

    it('throws when manifest.name disagrees with its directory name', async () => {
      fetchSpy
        .mockResolvedValueOnce(
          new Response(
            JSON.stringify([{ name: 'wheels-sentry', type: 'dir' }]),
            { status: 200 },
          ),
        )
        .mockResolvedValueOnce(
          new Response(
            JSON.stringify({
              name: 'wheels-foo',
              description: 'x',
              versions: [
                { version: '1.0.0', publishedAt: '2026-04-01T00:00:00Z', wheelsVersion: '>=4.0', sourceTag: 'v1.0.0', tarball: 'x', sha256: 'y' },
              ],
            }),
            { status: 200 },
          ),
        );

      const { listAll } = await import('./registry');
      await expect(listAll()).rejects.toThrow(/Registry drift/);
    });
  });
});
