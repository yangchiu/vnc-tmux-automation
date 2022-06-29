





docker build -t vnc .
docker run -d -p 7900:7900 \
           -v $HOME/.ssh/id_rsa:/home/seluser/.ssh/id_rsa \
           -v $PWD/k3s.yaml:/home/seluser/k3s.yaml \
           -v $PWD/scripts:/home/seluser/scripts \
           -e AWS_ACCESS_KEY=$TF_VAR_aws_access_key \
           -e AWS_SECRET_KEY=$TF_VAR_aws_secret_key \
           vnc