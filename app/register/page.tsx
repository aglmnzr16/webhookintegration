"use client";
import { useState } from 'react';

export default function RegisterPage() {
  const [username, setUsername] = useState("");
  const [code, setCode] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = await fetch('/api/register', {
        method: 'POST',
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ username }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.error || 'Failed');
      setCode(data.code);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="max-w-xl mx-auto p-6 space-y-6">
      <h1 className="text-2xl font-bold">Register Roblox Username</h1>
      <form onSubmit={submit} className="space-y-4">
        <input
          className="w-full border rounded p-2"
          placeholder="Roblox username"
          value={username}
          onChange={(e) => setUsername(e.target.value)}
          required
        />
        <button
          className="px-4 py-2 bg-black text-white rounded disabled:opacity-50"
          disabled={loading}
        >
          {loading ? 'Processing...' : 'Get Code'}
        </button>
      </form>

      {error && <p className="text-red-600">{error}</p>}

      {code && (
        <div className="border rounded p-4 bg-gray-50">
          <p className="font-semibold">Your code:</p>
          <p className="text-xl font-mono">#{code}</p>
          <p className="text-sm mt-2">
            Letakkan kode ini di pesan donasi kamu, misalnya: "#${code} semangat!".
            Webhook akan otomatis mencocokkan donasi ke username kamu.
          </p>
        </div>
      )}
    </div>
  );
}
