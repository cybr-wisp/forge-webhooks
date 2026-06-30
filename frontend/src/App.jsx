import WebhookList from './components/WebhookList.jsx'
import './App.css'

export default function App() {
  return (
    <div className="app">
      <header>
        <h1>Webhook Vault</h1>
        <p>Ingested payloads, stored as JSONB, replayable in one click.</p>
      </header>
      <main>
        <WebhookList />
      </main>
    </div>
  )
}
