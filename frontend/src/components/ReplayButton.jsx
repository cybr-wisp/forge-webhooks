import { useState } from 'react'

export default function ReplayButton({ webhookId, onReplayed }) {
  const [status, setStatus] = useState('idle') // idle | sending | done | error
  const [result, setResult] = useState(null)

  const replay = async () => {
    const targetUrl = window.prompt('Replay target URL:', 'http://localhost:3000/api/v1/webhooks/replay-target')
    if (!targetUrl) return

    setStatus('sending')
    try {
      const res = await fetch(`/api/v1/webhooks/${webhookId}/replays`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ target_url: targetUrl }),
      })
      const data = await res.json()
      if (!res.ok) throw new Error(data.error || `Request failed: ${res.status}`)
      setResult(data)
      setStatus('done')
      onReplayed?.()
    } catch (err) {
      setResult({ error: err.message })
      setStatus('error')
    }
  }

  return (
    <div className="replay-cell">
      <button onClick={replay} disabled={status === 'sending'}>
        {status === 'sending' ? 'Replaying...' : 'Replay'}
      </button>
      {status === 'done' && (
        <span className="replay-result ok">{result.response_status} in {result.elapsed_ms}ms</span>
      )}
      {status === 'error' && (
        <span className="replay-result error">{result.error}</span>
      )}
    </div>
  )
}
