// Simple in-memory storage for Vercel serverless
// In production, consider using Vercel KV, Supabase, or other database

const memoryStore = new Map<string, any>();

export async function readJson<T>(fileName: string, fallback: T): Promise<T> {
  try {
    const data = memoryStore.get(fileName);
    return data !== undefined ? data : fallback;
  } catch (e) {
    console.warn('Error reading from memory store:', e);
    return fallback;
  }
}

export async function writeJson<T>(fileName: string, data: T): Promise<void> {
  try {
    memoryStore.set(fileName, data);
    console.log(`✅ Stored ${fileName} in memory`);
  } catch (e) {
    console.error('Error writing to memory store:', e);
    throw e;
  }
}

export function getDataPath(fileName: string) {
  return `memory://${fileName}`;
}
