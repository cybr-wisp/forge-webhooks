import { useEffect, useState } from 'react'
import ReplayButton from './ReplayButton.jsx'

export default function WebhookList() {
  const [events, setEvents] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const load = () => {
    setLoading(true)
    fetch('/api/v1/webhooks')
      .then((res) => {
        if (!res.ok) throw new Error(`Request failed: ${res.status}`)
        return res.json()
      })
      .then((data) => {
        setEvents(data)
        setError(null)
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false))
  }

  useEffect(() => {
    load()
  }, [])

  if (loading) return <p>Loading events...</p>
  if (error) return <p className="error">Error: {error}</p>
  if (events.length === 0) return <p>No webhook events yet. Send one to get started.</p>

  return (
    <table className="event-table">
      <thead>
        <tr>
          <th>ID</th>
          <th>Source</th>
          <th>Payload</th>
          <th>Received</th>
          <th>Replay</th>
        </tr>
      </thead>
      <tbody>
        {events.map((event) => (
          <tr key={event.id}>
            <td>{event.id}</td>
            <td>{event.source}</td>
            <td>
              <pre>{JSON.stringify(event.payload, null, 0)}</pre>
            </td>
            <td>{new Date(event.created_at).toLocaleString()}</td>
            <td>
              <ReplayButton webhookId={event.id} onReplayed={load} />
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
