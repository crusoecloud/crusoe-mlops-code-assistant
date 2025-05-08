You can test the website by running the docker locally with the following commands:
```bash
docker build -t novacode-front .
docker run -d --name novacode -p 8080:80 novacode-front
```
The website will be available at `http://localhost:8080`.
