export interface ManifestVersion {
  version: string;
  publishedAt: string;
  wheelsVersion: string;
  sourceTag: string;
  tarball: string;
  sha256: string;
}

export interface Manifest {
  name: string;
  description: string;
  homepage?: string;
  tags?: string[];
  versions: ManifestVersion[];
}

export interface PackageSummary {
  name: string;
  description: string;
  homepage: string;
  tags: string[];
  latestVersion: string;
  publishedAt: string;
}

const REPO = process.env.WHEELS_PACKAGES_REGISTRY ?? 'wheels-dev/wheels-packages';
const BRANCH = 'main';
const UA = 'wheels-dev/packages-site (https://packages.wheels.dev)';

async function getJson(url: string): Promise<unknown> {
  const res = await fetch(url, { headers: { 'User-Agent': UA } });
  if (!res.ok) {
    throw new Error(`Registry fetch failed: ${res.status} ${res.statusText} — ${url}`);
  }
  return res.json();
}

async function getText(url: string): Promise<string> {
  const res = await fetch(url, { headers: { 'User-Agent': UA } });
  if (!res.ok) {
    throw new Error(`Registry fetch failed: ${res.status} ${res.statusText} — ${url}`);
  }
  return res.text();
}

export async function listPackageNames(): Promise<string[]> {
  const url = `https://api.github.com/repos/${REPO}/contents/packages?ref=${BRANCH}`;
  const entries = (await getJson(url)) as Array<{ name: string; type: string }>;
  return entries.filter((e) => e.type === 'dir').map((e) => e.name).sort();
}

export async function fetchReadme(name: string): Promise<string> {
  const url = `https://raw.githubusercontent.com/${REPO}/${BRANCH}/packages/${name}/README.md`;
  return getText(url);
}

export async function fetchManifest(name: string): Promise<Manifest> {
  const url = `https://raw.githubusercontent.com/${REPO}/${BRANCH}/packages/${name}/manifest.json`;
  const raw = (await getJson(url)) as unknown;
  const manifest = raw as Manifest;
  if (
    !manifest ||
    typeof manifest !== 'object' ||
    !manifest.name ||
    !Array.isArray(manifest.versions)
  ) {
    throw new Error(`Malformed manifest for '${name}'`);
  }
  return manifest;
}

export async function listAll(): Promise<PackageSummary[]> {
  const names = await listPackageNames();
  const manifests = await Promise.all(names.map(fetchManifest));
  return manifests.map((m) => {
    const latest = m.versions[m.versions.length - 1];
    return {
      name: m.name,
      description: m.description ?? '',
      homepage: m.homepage ?? '',
      tags: m.tags ?? [],
      latestVersion: latest.version,
      publishedAt: latest.publishedAt,
    };
  });
}
