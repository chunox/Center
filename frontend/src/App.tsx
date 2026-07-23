import { useEffect, useState } from "react";
import { Route, Routes } from "react-router-dom";
import { apiClient } from "./api/client";

interface HealthResponse {
  status: string;
  environment: string;
}

function HomePage() {
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    apiClient
      .get<HealthResponse>("/health")
      .then(setHealth)
      .catch((err) =>
        setError(err instanceof Error ? err.message : "Error desconocido"),
      );
  }, []);

  return (
    <main style={{ padding: "2rem" }}>
      <h1>PM Tool</h1>
      {error && <p>No se pudo conectar al backend: {error}</p>}
      {health && (
        <p>
          Backend: {health.status} ({health.environment})
        </p>
      )}
      {!health && !error && <p>Conectando al backend...</p>}
    </main>
  );
}

function App() {
  return (
    <Routes>
      <Route path="/" element={<HomePage />} />
    </Routes>
  );
}

export default App;
