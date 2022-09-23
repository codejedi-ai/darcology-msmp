# snaptravel-intern-takehome-project

Run to build the docker image
`docker build -t infra-coop-takehome . `
Then RUN
`docker run -p 80:5000 -d -e RAILS_ENV="test" infra-coop-takehome`

RUN
'docker tag infra-coop-takehome codejediondockerhub/infra-coop-takehome' to add the tag


1. What is the URL of the hosted application?
http://35.174.192.126/

2. Briefly describe the technologies/platforms used (besides Docker and RoR). Describe where in the git repo these technologies/platforms are configured. If there are technologies/platforms configured manually in a web GUI or similar, include screenshots of all of the configuration.

I have used tar zip to install ruby-2.7.2 as `rbenv` does not have 2.7.2. Thus I need to install MRI Ruby v2.7.2 using a tar file.

I also used shell script to install ruby and run the app installation commands from the Dockerfile

I have used the ubuntu docker container as my base as I first ran the applicaion locally on an ubuntu machine. Then I would repeat the similar commands on the docker container. I used the aptitude library to install the variouse dependencies RoR need to run successfully.

Used Dockerhub to manage my docker images and version control. Through dockerhub I can deploy my image on an AWS EC2 instance. As of right now the image only supports linux/arm64/v8 platform
