# Snapcommerce Infra Co-op Takehome Challenge

## Description

In this challenge, you will take a legacy hello-world HTTP server application, containerize it using Docker, and deploy it to the cloud.

You do not need any previous experience with Ruby on Rails to complete this challenge, and no modifications or additions to the application code are necessary. You should be able to complete the challenge using a combination of the legacy application README below, previous experience, and online research. There is no time limit, but you should be able to complete it in less than 2 hours.

You may use any technologies or platforms you want, but you must containerize the application yourself and include a Dockerfile. If you incur any expenses during this challenge, we will reimburse you up to CAD$10. Send a receipt / screenshot of the expenses incurred to your recruiter 3 days after the stated due date.

## Requirements

1. The application is containerized via a Dockerfile placed in the root of the project. If someone were to run `docker build .` it would complete successfully.
1. A running version of the built docker image is accessible over HTTP over the public internet at an address provided by you at the root path. Eg. `http://some-domain.somewhere.com/` or `http://<someipv4address>/`
1. The message displayed is "Hello from production!". The last word in the message is controlled via the environment variable RAILS_ENV. Do not hardcode the value "production" into the application code or the built Docker image. Set the environment variable correctly at container launch time depending on your chosen platform / technology stack.

## Submission details and short-form questions

Submit your application to us by email as a g-zipped tarball (.tar.gz) of the repository root including the .git folder. **Do not submit a pull request or otherwise make a public submission or expose your code to the public**.

**Note: GMail does not allow direct attachments of compressed archives containing .js files. Please follow these instructions to submit your assignment via Google Drive link instead:**

https://support.google.com/mail/answer/6590?hl=en#zippy=%2Cmessages-that-have-attachments

You can also send us a Dropbox link, etc.

Your final submission should be committed to the master branch, without erasing or changing the existing commit history.

The application should be available at the URL you provided for 3 days past the stated due date.

Answer these questions in the README of your submission

1. What is the URL of the hosted application?

1. Briefly describe the technologies/platforms used (besides Docker and RoR). Describe where in the git repo these technologies/platforms are configured. If there are technologies/platforms configured manually in a web GUI or similar, include screenshots of all of the configuration.

# Legacy application README

## Setup / prerequisites

Requires MRI Ruby v2.7.2

Requires bundler 2.1.4: `gem install bundler -v 2.1.4`
 
To install library dependencies: `bundle install`

## Running the test suite

To run the test suite: `bundle exec rspec -fd`

## Running the server

To run the http server bound to all interfaces and listening to port 5000: `bundle exec rails server -b 0.0.0.0 -p 5000`
