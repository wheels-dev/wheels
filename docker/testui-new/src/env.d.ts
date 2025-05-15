/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE: string;
  readonly VITE_MOCK_API: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}