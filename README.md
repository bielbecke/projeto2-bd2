primeiro terminal:

cd backend

python3 -m venv venv

venv/Scripts/activate 

pip install -r requirements.txt

python main.py

------------------
segundo terminal:

cd frontend

npm install

npm run dev

----------------
Container Docker

docker run -d --name postgres-projeto2 -e POSTGRES_DB=projeto2 -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 postgres:16
docker start postgres-projeto2