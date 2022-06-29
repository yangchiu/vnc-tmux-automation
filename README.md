





docker build -t vnc .
docker run -d -p 7900:7900 -v $HOME/.ssh/id_rsa:/home/seluser/.ssh/id_rsa -v $PWD/k3s.yaml:/home/seluser/k3s.yaml vnc