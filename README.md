# snaptravel-intern-takehome-project


Run to build the docker image
`docker build -t infra-coop-takehome . `


Run
`docker run -p 80:5000 -e RAILS_ENV="<env-name>" infra-coop-takehome`
to run the docker locally, as of right now it only supports ARMv8 devices


Type `http://0.0.0.0:80` in the browser to view
