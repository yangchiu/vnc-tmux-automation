





docker build -t vnc .
docker run -d -p 7900:7900 \
           -v $HOME/.ssh/id_rsa:/home/seluser/.ssh/id_rsa \
           -v $PWD/k3s.yaml:/home/seluser/k3s.yaml \
           -v $PWD/features:/home/seluser/features \
           -e AWS_ACCESS_KEY_ID=$TF_VAR_aws_access_key \
           -e AWS_SECRET_ACCESS_KEY=$TF_VAR_aws_secret_key \
           -e AWS_DEFAULT_REGION=us-east-1 \
           --name vnc \
           vnc
docker container stop vnc && docker container rm vnc

/home/seluser/.local/bin/behave
