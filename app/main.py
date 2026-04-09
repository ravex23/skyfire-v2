from fastapi import FastAPI

app = FastAPI(title="SkyFire API", version="0.1.0")

@app.get("/")
def root():
    return {"message": "SkyFire v1 is alive 🔥"}

@app.get("/health")
def health():
    return {"status": "ok"}