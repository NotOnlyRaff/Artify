# Usa un'immagine Python leggera
FROM python:3.11-slim

# Crea e imposta la directory di lavoro
WORKDIR /app

# Copia i file del progetto
COPY . /app

# Installa le dipendenze
RUN pip install --no-cache-dir -r requirements.txt

# Esponi la porta usata da FastAPI
EXPOSE 8080

# Avvia l'app con FastAPI standard (che internamente usa Uvicorn)
CMD ["fastapi", "run", "main.py", "--port", "8080"]
